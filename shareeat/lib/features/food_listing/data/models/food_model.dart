import 'package:cloud_firestore/cloud_firestore.dart';

class FoodModel {
  // Core identifiers
  final String id;
  final String ownerId;

  // Food info
  final String title;
  final String description;

  // Quantity
  final int quantity;
  final int quantityAvailable;

  // Dates
  final DateTime createdAt;
  final DateTime expiryDate;

  // Attributes
  final bool isHalal;
  final String status; // available / reserved / completed (future)

  // Media
  final String? imageUrl;

  // Location (geo)
  final double latitude;
  final double longitude;

  // Optional display fields (UI-friendly)
  final String? locationName;
  final String? donorName;
  final String? category;

  FoodModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.quantity,
    required this.quantityAvailable,
    required this.createdAt,
    required this.expiryDate,
    required this.isHalal,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.locationName,
    this.donorName,
    this.category,
  });

  // -----------------------------
  // Firestore → Model
  // -----------------------------
  factory FoodModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return FoodModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',

      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      quantityAvailable:
          (data['quantityAvailable'] as num?)?.toInt() ??
              (data['quantity'] as num?)?.toInt() ??
              0,

      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate:
          (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),

      isHalal: data['isHalal'] as bool? ?? false,
      status: data['status'] as String? ?? 'available',

      imageUrl: data['imageUrl'] as String?,

      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,

      // Optional fields (safe for UI popup)
      locationName: data['locationName'] as String?,
      donorName: data['donorName'] as String?,
      category: data['category'] as String?,
    );
  }

  // -----------------------------
  // Model → Firestore
  // -----------------------------
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
      'createdAt': FieldValue.serverTimestamp(),

      // Optional
      'locationName': locationName,
      'donorName': donorName,
      'category': category,
    };
  }

  // -----------------------------
  // UI helpers (optional but useful)
  // -----------------------------
  bool get isAvailable =>
      status == 'available' && quantityAvailable > 0;

  bool get isExpired =>
      DateTime.now().isAfter(expiryDate);
}
