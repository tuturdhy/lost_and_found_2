import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';  // ✅ Pour Color
import '../models/item_model.dart';
import 'notification_service.dart';

// ============================================================================
// ✅ CLASSE 1 : MatchResult (résultat d'un matching)
// ============================================================================
class MatchResult {
  final ItemModel item;
  final int score;
  final List<String> matchedKeywords;
  final bool sameCategory;
  final bool sameColor;
  final double distance;

  MatchResult({
    required this.item,
    required this.score,
    required this.matchedKeywords,
    required this.sameCategory,
    required this.sameColor,
    this.distance = 0.0,
  });

  String get scoreLabel {
    if (score >= 80) return '🔥 Très forte';
    if (score >= 60) return '✅ Forte';
    if (score >= 40) return '⚠️ Possible';
    return '🔎 Faible';
  }

  Color get scoreColor {
    if (score >= 80) return const Color(0xFF2ED573);
    if (score >= 60) return const Color(0xFFFFA502);
    return const Color(0xFF94A3B8);
  }
}  // ✅ FIN DE MatchResult — ACOLADE FERMANTE ICI !

// ============================================================================
// ✅ CLASSE 2 : MatchingService (logique de matching)
// ============================================================================
class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notifService = NotificationService();

  Future<List<MatchResult>> findMatchesForItem(ItemModel newItem) async {
    try {
      final oppositeType = newItem.type == 'lost' ? 'found' : 'lost';

      final snapshot = await _firestore
          .collection('items')
          .where('type', isEqualTo: oppositeType)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final candidates = snapshot.docs.map(ItemModel.fromFirestore).toList();
      final results = <MatchResult>[];

      for (final candidate in candidates) {
        if (candidate.userId == newItem.userId) continue;
        final result = _computeScore(newItem, candidate);
        if (result.score >= 30) results.add(result);
      }

      results.sort((a, b) => b.score.compareTo(a.score));

      final topMatches = results.take(5).toList();
      for (final match in topMatches) {
        await _saveMatch(newItem, match);
        await _sendMatchNotifications(newItem, match);
      }

      return topMatches;
    } catch (e) {
      print('❌ Erreur findMatchesForItem: $e');
      return [];
    }
  }

  MatchResult _computeScore(ItemModel query, ItemModel candidate) {
    int score = 0;
    bool sameCategory = false;
    bool sameColor = false;
    final List<String> matchedKeywords = [];

    if (query.category.isNotEmpty && candidate.category.isNotEmpty &&
        query.category.toLowerCase() == candidate.category.toLowerCase()) {
      score += 35;
      sameCategory = true;
    }

    if (query.color.isNotEmpty && candidate.color.isNotEmpty &&
        query.color.toLowerCase() == candidate.color.toLowerCase()) {
      score += 25;
      sameColor = true;
    }

    for (final kw in query.keywords) {
      if (kw.isEmpty) continue;
      final kwLower = kw.toLowerCase().trim();
      if (candidate.keywords.any((k) => k.toLowerCase().trim() == kwLower)) {
        matchedKeywords.add(kw);
        score += 8;
      }
    }

    final distance = _calculateDistance(
      query.latitude, query.longitude,
      candidate.latitude, candidate.longitude,
    );
    if (distance < 2.0) score += 10;

    if (_titleSimilarity(query.title, candidate.title)) score += 5;

    score = score.clamp(0, 100);

    return MatchResult(
      item: candidate,
      score: score,
      matchedKeywords: matchedKeywords,
      sameCategory: sameCategory,
      sameColor: sameColor,
      distance: distance,
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);

  bool _titleSimilarity(String title1, String title2) {
    final words1 = title1.toLowerCase().split(' ').where((w) => w.length > 3).toSet();
    final words2 = title2.toLowerCase().split(' ').where((w) => w.length > 3).toSet();
    return words1.intersection(words2).length >= 2;
  }

  Future<void> _saveMatch(ItemModel item, MatchResult result) async {
    try {
      await _firestore.collection('matches').add({
        'lostItemId': item.type == 'lost' ? item.id : result.item.id,
        'foundItemId': item.type == 'found' ? item.id : result.item.id,
        'lostUserId': item.type == 'lost' ? item.userId : result.item.userId,
        'foundUserId': item.type == 'found' ? item.userId : result.item.userId,
        'newItemId': item.id,
        'matchedItemId': result.item.id,
        'score': result.score,
        'matchedKeywords': result.matchedKeywords,
        'distance': result.distance,
        'notified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur sauvegarde match: $e');
    }
  }

  Future<void> _sendMatchNotifications(ItemModel newItem, MatchResult match) async {
    try {
      final isLost = newItem.type == 'lost';
      final matchType = isLost ? 'trouvé' : 'perdu';
      
      await _notifService.notifyMatch(
        userId: newItem.userId,
        itemTitle: newItem.title,
        score: match.score,
        matchedItemId: match.item.id,
        matchedItemTitle: match.item.title,
        matchType: matchType,
        distance: match.distance,
      );
      
      await _notifService.notifyMatch(
        userId: match.item.userId,
        itemTitle: match.item.title,
        score: match.score,
        matchedItemId: newItem.id,
        matchedItemTitle: newItem.title,
        matchType: isLost ? 'perdu' : 'trouvé',
        distance: match.distance,
      );
      
      await _firestore
          .collection('matches')
          .where('newItemId', isEqualTo: newItem.id)
          .where('matchedItemId', isEqualTo: match.item.id)
          .limit(1)
          .get()
          .then((snapshot) {
            for (final doc in snapshot.docs) {
              doc.reference.update({'notified': true});
            }
          });
    } catch (e) {
      print('❌ Erreur envoi notifications: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getUserMatches(String userId) {
    return _firestore
        .collection('matches')
        .where('lostUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              return {'id': d.id, ...d.data() as Map<String, dynamic>};
            }).toList());
  }
}  // ✅ FIN DE MatchingService