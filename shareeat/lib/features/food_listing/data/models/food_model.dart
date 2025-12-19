import 'package:cloud_firestore/cloud_firestore.dart';

class FoodModel {
  final String id;
  final String ownerId;

  final String title;
  final String description;

  final int quantity;
  final int quantityAvailable;

  final DateTime expiryDate;
  final bool isHalal;

  final String? imageUrl;

  final double latitude;
  final double longitude;

  /// "available" only for now (later can add reserved/completed)
  final String status;

  final DateTime createdAt;

  FoodModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.quantity,
    required this.quantityAvailable,
    required this.expiryDate,
    required this.isHalal,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'quantity': quantity,
      'quantityAvailable': quantityAvailable,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isHalal': isHalal,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(), // important
    };
  }

  factory FoodModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return FoodModel(
      id: doc.id,
      ownerId: (data['ownerId'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      quantity: (data['quantity'] ?? 0) as int,
      quantityAvailable: (data['quantityAvailable'] ?? data['quantity'] ?? 0) as int,
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isHalal: (data['isHalal'] ?? false) as bool,
      imageUrl: data['imageUrl'] as String?,
      latitude: ((data['latitude'] as num?) ?? 0).toDouble(),
      longitude: ((data['longitude'] as num?) ?? 0).toDouble(),
      status: (data['status'] ?? 'available') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}