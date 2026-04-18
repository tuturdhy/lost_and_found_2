import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'match', 'message', 'resolved'
  final String? itemId;
  final String? matchedItemTitle; // ✅ NOUVEAU : Titre de l'objet correspondant
  final String? matchType;        // ✅ NOUVEAU : 'trouvé' ou 'perdu'
  final double? distance;         // ✅ NOUVEAU : Distance en km
  final int? score;               // ✅ NOUVEAU : Score de match
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.itemId,
    this.matchedItemTitle,
    this.matchType,
    this.distance,
    this.score,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'match',
      itemId: data['itemId'],
      matchedItemTitle: data['matchedItemTitle'],
      matchType: data['matchType'],
      distance: (data['distance'] as num?)?.toDouble(),
      score: data['score'] as int?,
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  IconData get icon {
    switch (type) {
      case 'match':
        return Icons.search_rounded;
      case 'message':
        return Icons.chat_rounded;
      case 'resolved':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (type) {
      case 'match':
        return const Color(0xFFE94560);
      case 'message':
        return const Color(0xFF0F3460);
      case 'resolved':
        return const Color(0xFF2ED573);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Envoyer une notification générique à un utilisateur
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? itemId,
    String? matchedItemTitle,
    String? matchType,
    double? distance,
    int? score,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'itemId': itemId,
        'matchedItemTitle': matchedItemTitle,    // ✅ NOUVEAU
        'matchType': matchType,                  // ✅ NOUVEAU
        'distance': distance,                    // ✅ NOUVEAU
        'score': score,                          // ✅ NOUVEAU
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur envoi notification: $e');
    }
  }

  /// ✅ Notifier quand un match est trouvé (signature mise à jour)
  Future<void> notifyMatch({
    required String userId,
    required String itemTitle,
    required int score,
    required String matchedItemId,
    required String matchedItemTitle,  // ✅ NOUVEAU
    required String matchType,         // ✅ NOUVEAU : 'trouvé' ou 'perdu'
    required double distance,          // ✅ NOUVEAU
  }) async {
    await sendNotification(
      userId: userId,
      title: '🎯 Correspondance ${matchType}e !',
      body: 'Un objet "$matchedItemTitle" a été ${matchType} et correspond à "$itemTitle" (${score}% - ${distance.toStringAsFixed(1)} km)',
      type: 'match',
      itemId: matchedItemId,
      matchedItemTitle: matchedItemTitle,
      matchType: matchType,
      distance: distance,
      score: score,
    );
  }

  /// ✅ Notifier quand un message est reçu
  Future<void> notifyMessage({
    required String userId,
    required String senderName,
    required String message,
    String? chatId,
  }) async {
    await sendNotification(
      userId: userId,
      title: '💬 Nouveau message de $senderName',
      body: message,
      type: 'message',
      itemId: chatId,
    );
  }

  /// ✅ Notifier quand un objet est résolu
  Future<void> notifyResolved({
    required String userId,
    required String itemTitle,
  }) async {
    await sendNotification(
      userId: userId,
      title: '🎉 Objet retrouvé !',
      body: '"$itemTitle" a été marqué comme retrouvé. Bravo !',
      type: 'resolved',
    );
  }

  /// ✅ Stream des notifications d'un utilisateur (temps réel)
  Stream<List<AppNotification>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.id, d.data()))
            .toList());
  }

  /// ✅ Compter les notifications non lues
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// ✅ Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Erreur markAsRead: $e');
    }
  }

  /// ✅ Tout marquer comme lu pour un utilisateur
  Future<void> markAllAsRead(String userId) async {
    try {
      final snap = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
          
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('❌ Erreur markAllAsRead: $e');
    }
  }

  /// ✅ Afficher une snackbar de notification in-app (statique)
  static void showInAppNotification(
    BuildContext context, {
    required String title,
    required String body,
    required Color color,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            onTap?.call();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon ?? Icons.notifications_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        body,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}