import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shareeat/features/food_listing/data/data/models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ===============================
  /// CREATE BOOKING (REQUEST FOOD)
  /// ===============================
  Future<void> createBooking(BookingModel booking) async {
    await _db.collection('bookings').add(booking.toJson());
  }

  /// =========================================
  /// REQUESTER VIEW: MY REQUESTS
  /// =========================================
  Stream<List<BookingModel>> watchMyBookings(String userId) {
    return _db
        .collection('bookings')
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BookingModel.fromDoc).toList());
  }

  /// =========================================
  /// DONOR VIEW: MY DONATIONS (INCOMING REQUESTS)
  /// =========================================
  Stream<List<BookingModel>> watchMyDonations(String ownerId) {
    return _db
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BookingModel.fromDoc).toList());
  }

  /// =========================================
  /// QR VERIFICATION: MARK BOOKING AS COMPLETED
  /// =========================================
  Future<void> markBookingCompleted(String bookingId) async {
    await _db
        .collection('bookings')
        .doc(bookingId)
        .update({
          'status': 'completed',
        });
  }

  /// =========================================
  /// OPTIONAL: DONOR ACCEPT REQUEST
  /// (USE IF YOU ADD ACCEPT / REJECT LATER)
  /// =========================================
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _db
        .collection('bookings')
        .doc(bookingId)
        .update({
          'status': status,
        });
  }
}
