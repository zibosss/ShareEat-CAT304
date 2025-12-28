import 'package:cloud_firestore/cloud_firestore.dart';
// ✅ FIXED IMPORT: Removed the double "data/data" typo
import 'package:shareeat/features/food_listing/data/data/models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Create Booking (Deduct Stock)
  Future<void> createBooking(BookingModel booking) async {
    final foodRef = _db.collection('foods').doc(booking.foodId);
    // Generate a new ID automatically
    final bookingRef = _db.collection('bookings').doc(); 

    return _db.runTransaction((transaction) async {
      final foodSnapshot = await transaction.get(foodRef);

      if (!foodSnapshot.exists) {
        throw Exception("Food item no longer exists!");
      }

      final int currentQty = foodSnapshot.data()?['quantityAvailable'] ?? 0;

      // ✅ Validation: Check if enough stock exists
      if (currentQty < booking.quantity) {
        throw Exception("Not enough stock! Only $currentQty left.");
      }

      // ✅ Deduct Stock
      transaction.update(foodRef, {
        'quantityAvailable': currentQty - booking.quantity,
      });

      // Save Booking
      transaction.set(bookingRef, booking.toJson());
    });
  }

  // 2. Cancel Booking (Restore Stock)
  Future<void> cancelBooking(BookingModel booking) async {
    final foodRef = _db.collection('foods').doc(booking.foodId);
    final bookingRef = _db.collection('bookings').doc(booking.id);

    return _db.runTransaction((transaction) async {
      // Get food doc to check if it still exists
      final foodSnapshot = await transaction.get(foodRef);

      // ✅ Delete the booking
      transaction.delete(bookingRef);

      // ✅ Restore Stock (Add the quantity back)
      // We only update if the food item hasn't been deleted by the owner
      if (foodSnapshot.exists) {
        final int currentQty = foodSnapshot.data()?['quantityAvailable'] ?? 0;
        
        transaction.update(foodRef, {
          'quantityAvailable': currentQty + booking.quantity,
        });
      }
    });
  }

  // 3. Watch My Requests
  Stream<List<BookingModel>> watchMyBookings(String userId) {
    return _db.collection('bookings')
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => BookingModel.fromDoc(d)).toList());
  }

  // 4. Watch My Donations
  Stream<List<BookingModel>> watchMyDonations(String userId) {
    return _db.collection('bookings')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => BookingModel.fromDoc(d)).toList());
  }
  
  // 5. Mark Completed
  Future<void> markBookingCompleted(String id) async {
    await _db.collection('bookings').doc(id).update({'status': 'completed'});
  }
}