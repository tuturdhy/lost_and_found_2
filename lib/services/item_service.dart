import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
// ❌ SUPPRIMÉ: import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';
import 'cloudinary_service.dart'; // ✅ AJOUTÉ: Import Cloudinary

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ❌ SUPPRIMÉ: final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // ✅ Upload photo vers Cloudinary (ou retourne null)
  Future<String?> uploadPhoto(File imageFile, String userId) async {
    try {
      // Option 1: Utiliser Cloudinary
      return await CloudinaryService.uploadImage(imageFile);
      
      // Option 2: Retourner null si tu veux tester sans images
      // return null;
    } catch (e) {
      print('❌ Erreur upload photo: $e');
      return null; // Retourne null en cas d'erreur (graceful degradation)
    }
  }

  // ✅ Publier un objet (photoUrl est maintenant nullable)
  Future<String> publishItem({
    required String userId,
    required String userName,
    required String userAvatar,
    required String type,
    required String title,
    required String description,
    required String? photoUrl,  // ✅ NULLABLE !
    required String category,
    required List<String> keywords,
    required String color,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final docRef = _firestore.collection('items').doc();
    
    final item = ItemModel(
      id: docRef.id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      type: type,
      title: title,
      description: description,
      photoUrl: photoUrl,  // ✅ Peut être null
      category: category,
      keywords: keywords,
      color: color,
      latitude: latitude,
      longitude: longitude,
      address: address,
      status: 'active',
      createdAt: DateTime.now(),
    );
    
    await docRef.set(item.toMap());

    // Incrémenter le compteur utilisateur
    await _firestore.collection('users').doc(userId).update({
      'itemsPublished': FieldValue.increment(1),
    });

    return docRef.id;
  }

  // ✅ Récupérer tous les objets actifs (stream temps réel)
  Stream<List<ItemModel>> getActiveItems() {
    return _firestore
        .collection('items')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ItemModel.fromFirestore).toList());
  }
// ✅ Récupérer les objets actifs DES AUTRES utilisateurs
// ✅ Récupérer les objets actifs DES AUTRES utilisateurs
Stream<List<ItemModel>> getActiveItemsFromOthers(String currentUserId) {
  return _firestore
      .collection('items')
      .where('status', isEqualTo: 'active')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) {
        final items = snap.docs.map(ItemModel.fromFirestore).toList();
        // ✅ Filtrer en mémoire (pas de limitation Firestore)
        return items.where((item) => item.userId != currentUserId).toList();
      });
}
  // ✅ Récupérer les objets d'un utilisateur
  Stream<List<ItemModel>> getUserItems(String userId) {
    return _firestore
        .collection('items')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ItemModel.fromFirestore).toList());
  }

  // ✅ Marquer comme résolu
  Future<void> markAsResolved(String itemId, String userId) async {
    await _firestore.collection('items').doc(itemId).update({
      'status': 'resolved',
    });
    await _firestore.collection('users').doc(userId).update({
      'itemsResolved': FieldValue.increment(1),
      'reputationScore': FieldValue.increment(1),
    });
  }

  // ✅ Algorithme de matching (inchangé)
  List<Map<String, dynamic>> findMatches(
      ItemModel newItem, List<ItemModel> existingItems) {
    final List<Map<String, dynamic>> matches = [];
    final oppositeType = newItem.type == 'lost' ? 'found' : 'lost';

    for (final item in existingItems) {
      if (item.type != oppositeType || item.status != 'active') continue;
      if (item.userId == newItem.userId) continue;

      // Calcul du score de similarité
      int score = 0;

      // Même catégorie = +40 points
      if (item.category == newItem.category) score += 40;

      // Même couleur = +20 points
      if (item.color.isNotEmpty &&
          newItem.color.isNotEmpty &&
          item.color == newItem.color) score += 20;

      // Mots-clés en commun
      final commonKeywords =
          item.keywords.where((k) => newItem.keywords.contains(k)).length;
      score += commonKeywords * 10;

      if (score >= 40) {
        matches.add({'item': item, 'score': score.clamp(0, 100)});
      }
    }

    matches.sort((a, b) => b['score'].compareTo(a['score']));
    return matches.take(3).toList();
  }
}