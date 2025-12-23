import 'package:cloud_firestore/cloud_firestore.dart';

// Reuse BookingModel from food_listing via package import
import 'package:shareeat/features/food_listing/data/models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a new request
  Future<void> createBooking(BookingModel booking) async {
    await _db.collection('bookings').add(booking.toJson());
  }

  // Get list of requests made by the current user
  Stream<List<BookingModel>> watchMyBookings(String userId) {
    return _db
        .collection('bookings')
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BookingModel.fromDoc).toList());
  }
}
