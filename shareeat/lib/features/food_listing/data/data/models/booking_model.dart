// TODO Implement this library.
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String foodId;
  final String foodTitle;
  final String? foodImage;
  final String requesterId;
  final String ownerId;
  final String status; // e.g., 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.foodId,
    required this.foodTitle,
    this.foodImage,
    required this.requesterId,
    required this.ownerId,
    required this.status,
    required this.createdAt, required String qrCodeData,
  });

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'foodTitle': foodTitle,
      'foodImage': foodImage,
      'requesterId': requesterId,
      'ownerId': ownerId,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory BookingModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BookingModel(
      id: doc.id,
      foodId: data['foodId'] ?? '',
      foodTitle: data['foodTitle'] ?? '',
      foodImage: data['foodImage'],
      requesterId: data['requesterId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(), qrCodeData: '',
    );
  }

  String? get qrCodeData => null;
}