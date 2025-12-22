import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shareeat/features/food_listing/data/data/models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ NEW: Create Booking AND Deduct Quantity Safely
  Future<void> createBooking(BookingModel booking) async {
    final foodRef = _db.collection('foods').doc(booking.foodId);
    final bookingRef = _db.collection('bookings').doc(); // Generate a new ID

    return _db.runTransaction((transaction) async {
      // 1. Get the current food document
      final foodSnapshot = await transaction.get(foodRef);

      if (!foodSnapshot.exists) {
        throw Exception("Food item no longer exists!");
      }

      // 2. Check current quantity
      // (Assuming the field in Firebase is 'quantityAvailable')
      final int currentQty = foodSnapshot.data()?['quantityAvailable'] ?? 0;

      if (currentQty <= 0) {
        throw Exception("Sorry, this food is now out of stock!");
      }

      // 3. Deduct Quantity by 1
      transaction.update(foodRef, {
        'quantityAvailable': currentQty - 1,
      });

      // 4. Save the Booking
      // We manually add the ID if your model needs it, or just save the data
      transaction.set(bookingRef, booking.toJson());
    });
  }

  // Watch My Requests
  Stream<List<BookingModel>> watchMyBookings(String userId) {
    return _db
        .collection('bookings')
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BookingModel.fromDoc(doc)).toList());
  }

  // Watch My Donations
  Stream<List<BookingModel>> watchMyDonations(String userId) {
    return _db
        .collection('bookings')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BookingModel.fromDoc(doc)).toList());
  }

  // Mark Completed
  Future<void> markBookingCompleted(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': 'completed',
    });
  }
}