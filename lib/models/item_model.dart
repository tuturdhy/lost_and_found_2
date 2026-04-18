import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String type; // 'lost' or 'found'
  final String title;
  final String description;
  
  // ✅ CHANGEMENT 1: photoUrl est maintenant nullable
  final String? photoUrl;
  
  final String category;
  final List<String> keywords;
  final String color;
  final double latitude;
  final double longitude;
  final String address;
  final String status; // 'active' or 'resolved'
  final DateTime createdAt;

  ItemModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.type,
    required this.title,
    required this.description,
    
    // ✅ CHANGEMENT 2: photoUrl n'est plus required et est nullable
    this.photoUrl,
    
    required this.category,
    required this.keywords,
    required this.color,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.status,
    required this.createdAt,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Utilisateur',
      userAvatar: data['userAvatar'] ?? '',
      type: data['type'] ?? 'lost',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      
      // ✅ CHANGEMENT 3: photoUrl peut être null
      photoUrl: data['photoUrl'] as String?,
      
      category: data['category'] ?? 'autre',
      keywords: List<String>.from(data['keywords'] ?? []),
      color: data['color'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'type': type,
      'title': title,
      'description': description,
      
      // ✅ CHANGEMENT 4: photoUrl peut être null dans Firestore
      'photoUrl': photoUrl,
      
      'category': category,
      'keywords': keywords,
      'color': color,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}