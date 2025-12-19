// TODO Implement this library.
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shareeat/features/food_listing/data/models/models/booking_model.dart';

// -----------------------------------------------------------------------------
// IMPORTANT: Fix these imports using "Quick Fix" (Ctrl + .) if they are red.
// They must point to where you saved these files in your project.
// -----------------------------------------------------------------------------
import '../data/models/food_model.dart';
import '../data/models/booking_model.dart' hide BookingModel;      // Created in Step 1
import '../data/models/booking_repository.dart';         // Created in Step 2

class BookingDetailScreen extends StatefulWidget {
  final FoodModel food;

  const BookingDetailScreen({
    super.key,
    required this.food,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  // Map Controller
  final Completer<GoogleMapController> _controller = Completer();
  
  // Set of markers
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setMarker();
  }

  void _setMarker() {
    // Create a marker for the food location
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(widget.food.id),
          position: LatLng(widget.food.latitude, widget.food.longitude),
          infoWindow: InfoWindow(title: widget.food.title),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Format dates for display
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final expiryFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ---------------------------------------------------------
              // 1. SLIVER APP BAR (Header Image)
              // ---------------------------------------------------------
              SliverAppBar(
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF7A2B93),
                flexibleSpace: FlexibleSpaceBar(
                  background: widget.food.imageUrl != null && widget.food.imageUrl!.isNotEmpty
                      ? Image.network(
                          widget.food.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFF7A2B93).withOpacity(0.2),
                          child: const Icon(Icons.fastfood, size: 80, color: Color(0xFF7A2B93)),
                        ),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // ---------------------------------------------------------
              // 2. CONTENT BODY
              // ---------------------------------------------------------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -- Top Row: Halal Badge & Expiry --
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: widget.food.isHalal ? Colors.green[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: widget.food.isHalal ? Colors.green : Colors.orange,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  widget.food.isHalal ? Icons.check_circle : Icons.warning,
                                  size: 14,
                                  color: widget.food.isHalal ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.food.isHalal ? 'Halal' : 'Non-Halal',
                                  style: TextStyle(
                                    color: widget.food.isHalal ? Colors.green[700] : Colors.orange[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.timer_outlined, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            "Expires: ${expiryFormat.format(widget.food.expiryDate)}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 15),

                      // -- Title & Quantity Badge --
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.food.title,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7A2B93),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7A2B93).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text("Available", style: TextStyle(fontSize: 10, color: Colors.white70)),
                                Text(
                                  "${widget.food.quantityAvailable}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 8),
                      
                      // -- Posted Date --
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 5),
                          Text(
                            "Posted on ${dateFormat.format(widget.food.createdAt)}",
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),
                      const Divider(thickness: 1),
                      const SizedBox(height: 15),

                      // -- Description --
                      const Text(
                        "Description",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.food.description,
                        style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.6),
                      ),

                      const SizedBox(height: 30),

                      // -- Location Map --
                      const Text(
                        "Pickup Location",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(widget.food.latitude, widget.food.longitude),
                              zoom: 15,
                            ),
                            markers: _markers,
                            zoomControlsEnabled: false,
                            scrollGesturesEnabled: false, // Prevents interfering with page scroll
                            rotateGesturesEnabled: false,
                            onMapCreated: (GoogleMapController controller) {
                              _controller.complete(controller);
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      Text(
                        "Coordinates: ${widget.food.latitude.toStringAsFixed(5)}, ${widget.food.longitude.toStringAsFixed(5)}",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),

                      // Space for bottom button
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ---------------------------------------------------------
          // 3. STICKY BOTTOM BUTTON (Action Logic)
          // ---------------------------------------------------------
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: () async {
                    // 1. Get Current User
                    final user = FirebaseAuth.instance.currentUser;

                    // 2. Validation: Must be logged in
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please login to request food"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    // 3. Validation: Cannot request own food
                    if (user.uid == widget.food.ownerId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("You cannot request your own food"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    // 4. Create Booking Object
                    final newBooking = BookingModel(
                      id: '', // Firestore will generate this automatically
                      foodId: widget.food.id,
                      foodTitle: widget.food.title,
                      foodImage: widget.food.imageUrl,
                      requesterId: user.uid,
                      ownerId: widget.food.ownerId,
                      status: 'pending',
                      createdAt: DateTime.now(),
                    );

                    // 5. Save to Firestore via Repository
                    final repo = BookingRepository();
                    
                    try {
                      // Show Loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Sending request..."), duration: Duration(seconds: 1)),
                      );

                      await repo.createBooking(newBooking as BookingModel);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Request sent successfully!"), backgroundColor: Colors.green),
                        );
                        Navigator.pop(context); // Return to previous screen
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to send request: $e"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7A2B93),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Request Food",
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}