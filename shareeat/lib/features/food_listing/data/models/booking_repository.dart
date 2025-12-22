import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shareeat/features/food_listing/data/data/models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Create a Booking
  Future<void> createBooking(BookingModel booking) async {
    await _db.collection('bookings').add(booking.toJson());
  }

  // 2. Watch Requests (For the person asking for food)
  Stream<List<BookingModel>> watchMyBookings(String userId) {
    return _db
        .collection('bookings')
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BookingModel.fromDoc(doc)).toList());
  }

  // 3. Watch Donations (For the person GIVING food) -> THIS WAS LIKELY MISSING OR WRONG
  Stream<List<BookingModel>> watchMyDonations(String userId) {
    return _db
        .collection('bookings')
        .where('ownerId', isEqualTo: userId) // ✅ Looking for ownerId
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BookingModel.fromDoc(doc)).toList());
  }

  // 4. Mark as Completed (After QR Scan)
  Future<void> markBookingCompleted(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': 'completed',
    });
  }
}