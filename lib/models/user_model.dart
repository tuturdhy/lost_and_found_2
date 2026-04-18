import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final double reputationScore;
  final int itemsPublished;
  final int itemsResolved;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.reputationScore,
    required this.itemsPublished,
    required this.itemsResolved,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? 'Utilisateur',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      reputationScore: (data['reputationScore'] ?? 0.0).toDouble(),
      itemsPublished: data['itemsPublished'] ?? 0,
      itemsResolved: data['itemsResolved'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'reputationScore': reputationScore,
      'itemsPublished': itemsPublished,
      'itemsResolved': itemsResolved,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
