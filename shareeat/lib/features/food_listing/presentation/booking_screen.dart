import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shareeat/features/food_listing/data/data/models/booking_model.dart';

// IMPORTANT: Fix these imports to match your folder structure
import '../data/booking_repository.dart';


class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingRepository _repo = BookingRepository();
  
  // Get the current user's ID
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    // 1. Handle case where user is not logged in
    if (currentUserId == null) {
      return const Center(
        child: Text("Please log in to see your requests"),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Requests', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false, // Hides back button since it's a main tab
      ),
      // 2. StreamBuilder listens to Firestore updates in real-time
      body: StreamBuilder<List<BookingModel>>(
        stream: _repo.watchMyBookings(currentUserId!),
        builder: (context, snapshot) {
          // State: Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // State: Error
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bookings = snapshot.data ?? [];

          // State: Empty List
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "No requests made yet",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // State: Data Available -> Show List
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _BookingCard(booking: booking);
            },
          );
        },
      ),
    );
  }
}

// 3. Custom Card Widget to display a single booking
class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM, hh:mm a').format(booking.createdAt);
    
    // Determine color based on status
    Color statusColor;
    switch(booking.status.toLowerCase()) {
      case 'accepted': statusColor = Colors.green; break;
      case 'rejected': statusColor = Colors.red; break;
      case 'completed': statusColor = Colors.blue; break;
      default: statusColor = Colors.orange; // pending
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Food Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: booking.foodImage != null && booking.foodImage!.isNotEmpty
                ? Image.network(
                    booking.foodImage!, 
                    width: 70, 
                    height: 70, 
                    fit: BoxFit.cover
                  )
                : Container(
                    width: 70, height: 70,
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 15),
          
          // Food Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.foodTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  "Requested: $dateStr", 
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.5)),
            ),
            child: Text(
              booking.status.toUpperCase(),
              style: TextStyle(
                color: statusColor, 
                fontSize: 10, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ],
      ),
    );
  }
}