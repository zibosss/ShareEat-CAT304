import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String foodId;
  final String foodTitle;
  final String? foodImage;
  final String requesterId;
  final String ownerId;
  final String status;
  final String qrCodeData;
  final DateTime createdAt;
  final int quantity;
  
  // ✅ NEW FIELDS: Location Data
  final double latitude;
  final double longitude;

  BookingModel({
    required this.id,
    required this.foodId,
    required this.foodTitle,
    this.foodImage,
    required this.requesterId,
    required this.ownerId,
    required this.status,
    required this.qrCodeData,
    required this.createdAt,
    required this.quantity,
    
    // ✅ REQUIRED in Constructor
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'foodTitle': foodTitle,
      'foodImage': foodImage,
      'requesterId': requesterId,
      'ownerId': ownerId,
      'status': status,
      'qrCodeData': qrCodeData,
      'createdAt': FieldValue.serverTimestamp(),
      'quantity': quantity,
      
      // ✅ SAVE TO DB
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory BookingModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BookingModel(
      id: doc.id,
      foodId: data['foodId'] ?? '',
      foodTitle: data['foodTitle'] ?? '',
      foodImage: data['foodImage'] as String?,
      requesterId: data['requesterId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      status: data['status'] ?? 'pending',
      qrCodeData: data['qrCodeData'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      quantity: data['quantity'] ?? 1,
      
      // ✅ READ FROM DB (Handles both int and double safely)
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
    );
  }
}