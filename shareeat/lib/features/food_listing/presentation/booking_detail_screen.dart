import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shareeat/features/food_listing/data/data/models/booking_model.dart';

// ✅ CHECK IMPORTS: Fix these paths if they show red lines
import '../data/models/food_model.dart';
import 'package:shareeat/features/food_listing/data/models/booking_model.dart' hide BookingModel;
import 'package:shareeat/features/food_listing/data/booking_repository.dart';

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
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setMarker();
  }

  void _setMarker() {
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
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final expiryFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. APP BAR IMAGE
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
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

              // 2. CONTENT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Expiry
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
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 15),

                      // Title & Qty
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.food.title,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7A2B93),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text("Available", style: TextStyle(fontSize: 10, color: Colors.white70)),
                                Text(
                                  "${widget.food.quantityAvailable}",
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 8),
                      Text("Posted on ${dateFormat.format(widget.food.createdAt)}",
                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),

                      const SizedBox(height: 25),
                      const Divider(),
                      const SizedBox(height: 15),

                      const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(widget.food.description, style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.6)),

                      const SizedBox(height: 30),

                      const Text("Pickup Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                            scrollGesturesEnabled: false,
                            onMapCreated: (c) => _controller.complete(c),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 100), // Space for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. REQUEST BUTTON (With QR Logic)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;

                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please login to request food"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    if (user.uid == widget.food.ownerId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("You cannot request your own food"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    // --- GENERATE QR CODE STRING ---
                    // Format: SE-[UserID]-[Timestamp]
                    final String uniqueQrString = "SE-${user.uid.substring(0, 5)}-${DateTime.now().millisecondsSinceEpoch}";

                    final newBooking = BookingModel(
                      id: '',
                      foodId: widget.food.id,
                      foodTitle: widget.food.title,
                      foodImage: widget.food.imageUrl,
                      requesterId: user.uid,
                      ownerId: widget.food.ownerId,
                      status: 'pending',
                      qrCodeData: uniqueQrString, // ✅ Save the unique code
                      createdAt: DateTime.now(),
                    );

                    final repo = BookingRepository();
                    
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Processing Request..."), duration: Duration(seconds: 1)),
                      );

                      await repo.createBooking(newBooking);
;

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Request sent! QR Code Generated."), backgroundColor: Colors.green),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7A2B93),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Request Food", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}