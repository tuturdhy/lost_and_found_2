import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';  // ✅ IMPORTANT : Importer MessageModel depuis models/

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Générer un ID de chat unique entre 2 utilisateurs (trié alphabétiquement)
  String getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // ✅ Récupérer le nom d'affichage d'un utilisateur depuis Firestore
  Future<String> _getUserDisplayName(String userId) async {
    if (userId.isEmpty) return 'Utilisateur';
    
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        // Priorité : name > displayName > email > fallback
        return data?['name'] ?? 
               data?['displayName'] ?? 
               data?['email']?.split('@').first ?? 
               'Utilisateur';
      }
    } catch (e) {
      print('⚠️ Erreur récupération nom utilisateur: $e');
    }
    return 'Utilisateur';
  }

  // ✅ Envoyer un message (avec récupération du VRAI nom de l'autre utilisateur)
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String text,
    required String itemId,
    required String itemTitle,
    required List<String> participants,
  }) async {
    final now = DateTime.now();
    
    // ✅ Trouver l'ID de l'autre utilisateur
    final otherUserId = participants.firstWhere(
      (id) => id != senderId,
      orElse: () => '',
    );
    
    // ✅ Récupérer le VRAI nom de l'autre utilisateur
    final otherUserName = await _getUserDisplayName(otherUserId);
    
    // ✅ Récupérer l'avatar de l'autre utilisateur (optionnel)
    String? otherUserAvatar;
    if (otherUserId.isNotEmpty) {
      try {
        final userDoc = await _firestore.collection('users').doc(otherUserId).get();
        otherUserAvatar = userDoc.data()?['avatarUrl'] as String?;
      } catch (_) {}
    }

    // 1️⃣ Mettre à jour le document du chat (créer si n'existe pas)
    await _firestore.collection('chats').doc(chatId).set({
      'participants': participants,
      'itemId': itemId,
      'itemTitle': itemTitle,
      
      // ✅ Stocker le VRAI nom et avatar de l'autre utilisateur
      'otherUserName': otherUserName,
      'otherUserAvatar': otherUserAvatar ?? '',
      
      // ✅ Dernier message pour l'aperçu dans la liste
      'lastMessage': text,
      'lastMessageAt': Timestamp.fromDate(now),
      'lastMessageFromMe': senderId == participants.first,
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    // 2️⃣ Ajouter le message dans la sous-collection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'text': text,
      'createdAt': Timestamp.fromDate(now),
      'readBy': [senderId],
    });
  }

  // ✅ Retourne Stream<List<MessageModel>> avec import correct
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return MessageModel.fromMap(doc.id, data);
            }).toList());
  }

  // ✅ Récupérer tous les chats d'un utilisateur (avec unreadCount calculé)
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
          final chats = <Map<String, dynamic>>[];
          for (final doc in snap.docs) {
            final data = doc.data();
            final chatId = doc.id;
            final unreadCount = await _getUnreadCount(chatId, userId);
            chats.add({
              'id': chatId,
              ...data,
              'unreadCount': unreadCount,
            });
          }
          return chats;
        });
  }

  // ✅ Compter les messages non-lus dans un chat pour un utilisateur
  Future<int> _getUnreadCount(String chatId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();
      final total = snapshot.docs.length;
      final read = snapshot.docs.where((doc) {
        final readBy = List<String>.from(doc.data()['readBy'] ?? []);
        return readBy.contains(userId);
      }).length;
      return (total - read).clamp(0, 99);
    } catch (_) {
      return 0;
    }
  }

  // ✅ Stream du compte de messages non-lus pour un chat (temps réel)
  Stream<int> getUnreadCountStream(String chatId, String userId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots()
        .map((snap) {
          final total = snap.docs.length;
          final read = snap.docs.where((doc) {
            final readBy = List<String>.from(doc.data()['readBy'] ?? []);
            return readBy.contains(userId);
          }).length;
          return (total - read).clamp(0, 99);
        });
  }

  // ✅ Compter le nombre total de conversations avec des non-lus (pour le badge global)
  Stream<int> getUnreadChatsCount(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snap) async {
          int count = 0;
          for (final doc in snap.docs) {
            final unread = await _getUnreadCount(doc.id, userId);
            if (unread > 0) count++;
          }
          return count;
        });
  }

  // ✅ Marquer tous les messages d'un chat comme lus pour un utilisateur
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();
      final batch = _firestore.batch();
      int updatedCount = 0;  // ✅ Compteur manuel
      
      for (final doc in snapshot.docs) {
        final readBy = List<String>.from(doc.data()['readBy'] ?? []);
        if (!readBy.contains(userId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId]),
          });
          updatedCount++;
        }
      }
      
      if (updatedCount > 0) await batch.commit();  // ✅ Vérifier le compteur
    } catch (e) {
      print('❌ Erreur markMessagesAsRead: $e');
    }
  }

  // ✅ Marquer TOUTES les conversations comme lues pour un utilisateur
  Future<void> markAllChatsAsRead(String userId) async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();
      for (final chatDoc in chatsSnapshot.docs) {
        final chatId = chatDoc.id;
        final messagesSnapshot = await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .get();
        final batch = _firestore.batch();
        int updatedCount = 0;
        
        for (final msgDoc in messagesSnapshot.docs) {
          final readBy = List<String>.from(msgDoc.data()['readBy'] ?? []);
          if (!readBy.contains(userId)) {
            batch.update(msgDoc.reference, {
              'readBy': FieldValue.arrayUnion([userId]),
            });
            updatedCount++;
          }
        }
        if (updatedCount > 0) await batch.commit();
      }
    } catch (e) {
      print('❌ Erreur markAllChatsAsRead: $e');
    }
  }

  // ✅ Supprimer une conversation (optionnel)
  Future<void> deleteChat(String chatId) async {
    final messagesSnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();
    final batch = _firestore.batch();
    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('chats').doc(chatId));
    await batch.commit();
  }

  // ✅ Récupérer les infos d'un chat spécifique
  Future<Map<String, dynamic>?> getChatInfo(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  // ✅ Mettre à jour l'avatar de l'autre utilisateur dans un chat (quand il change)
  Future<void> updateParticipantAvatar({
    required String chatId,
    required String userId,
    required String avatarUrl,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      'otherUserAvatar': avatarUrl,
    });
  }

  // ✅ Mettre à jour le nom d'affichage dans tous les chats où l'utilisateur apparaît
  Future<void> updateUserDisplayName(String userId, String newName) async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();
          
      final batch = _firestore.batch();
      int updatedCount = 0;  // ✅ Compteur manuel (PAS batch.operations)
      
      for (final doc in chatsSnapshot.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );
        // Mettre à jour otherUserName pour l'autre participant
        if (otherUserId.isNotEmpty) {
          batch.update(doc.reference, {
            'otherUserName': newName,
          });
          updatedCount++;  // ✅ Incrémenter le compteur
        }
      }
      
      // ✅ Vérifier le compteur manuel au lieu de batch.operations
      if (updatedCount > 0) {
        await batch.commit();
        print('✅ Nom mis à jour dans $updatedCount conversation(s)');
      }
    } catch (e) {
      print('❌ Erreur updateUserDisplayName: $e');
    }
  }
}