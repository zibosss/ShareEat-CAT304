import 'package:cloud_firestore/cloud_firestore.dart';
// Adjust this import path if needed
import 'package:shareeat/features/food_listing/data/data/models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Create Booking (Deduct Stock)
  Future<void> createBooking(BookingModel booking) async {
    final foodRef = _db.collection('foods').doc(booking.foodId);
    final bookingRef = _db.collection('bookings').doc(); // Auto-ID

    return _db.runTransaction((transaction) async {
      final foodSnapshot = await transaction.get(foodRef);

      if (!foodSnapshot.exists) {
        throw Exception("Food item no longer exists!");
      }

      final int currentQty = foodSnapshot.data()?['quantityAvailable'] ?? 0;

      // Validation
      if (currentQty < booking.quantity) {
        throw Exception("Not enough stock! Only $currentQty left.");
      }

      // Deduct Stock
      transaction.update(foodRef, {
        'quantityAvailable': currentQty - booking.quantity,
      });

      // Save Booking
      transaction.set(bookingRef, booking.toJson());
    });
  }

  // 2. Cancel Booking (Restore Stock) - Manual Cancellation
  Future<void> cancelBooking(BookingModel booking) async {
    final foodRef = _db.collection('foods').doc(booking.foodId);
    final bookingRef = _db.collection('bookings').doc(booking.id);

    return _db.runTransaction((transaction) async {
      final foodSnapshot = await transaction.get(foodRef);

      // Delete the booking (or you could set status to 'cancelled' if you want to keep history)
      transaction.delete(bookingRef);

      // Restore Stock if food item still exists
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

  // ---------------------------------------------------------
  // ✅ 6. NEW FEATURE: Check and Expire Old Bookings (30 Mins)
  // ---------------------------------------------------------
  Future<void> checkAndExpireBookings(String userId) async {
    try {
      final now = DateTime.now();
      // Calculate 30 minutes ago
      final expirationThreshold = now.subtract(const Duration(minutes: 30));

      // Query: Find pending bookings for this user created BEFORE the threshold
      final snapshot = await _db.collection('bookings')
          .where('requesterId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .where('createdAt', isLessThan: expirationThreshold)
          .get();

      if (snapshot.docs.isEmpty) return; // Nothing to expire

      // Loop through expired items and restore stock
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String foodId = data['foodId'];
        // Default to 1 if quantity is missing
        final int quantityToRestore = data['quantity'] ?? 1;

        // Run safe transaction for each expiry
        await _db.runTransaction((transaction) async {
          final bookingRef = _db.collection('bookings').doc(doc.id);
          final foodRef = _db.collection('foods').doc(foodId);

          // A. Update status to 'expired' (so user sees it in history)
          transaction.update(bookingRef, {'status': 'expired'});

          // B. Restore the stock quantity
          // FieldValue.increment is safer than reading/writing manually here
          transaction.update(foodRef, {
            'quantityAvailable': FieldValue.increment(quantityToRestore)
          });
        });
      }
    } catch (e) {
      print("Error expiring bookings: $e");
    }
  }
}