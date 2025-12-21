import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shareeat/features/food_listing/data/models/booking_repository.dart';

// Correct imports
import 'package:shareeat/features/food_listing/data/models/food_model.dart';

import 'package:shareeat/features/food_listing/data/data/models/booking_model.dart';

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
    _markers.add(
      Marker(
        markerId: MarkerId(widget.food.id),
        position: LatLng(widget.food.latitude, widget.food.longitude),
        infoWindow: InfoWindow(title: widget.food.title),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ),
    );
    setState(() {});
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
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: const Color(0xFF7A2B93),
                flexibleSpace: FlexibleSpaceBar(
                  background: widget.food.imageUrl != null &&
                          widget.food.imageUrl!.isNotEmpty
                      ? Image.network(
                          widget.food.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.fastfood, size: 80),
                        ),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            child: Text(
                              widget.food.isHalal ? 'Halal' : 'Non-Halal',
                              style: TextStyle(
                                color: widget.food.isHalal ? Colors.green[700] : Colors.orange[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "Expires: ${expiryFormat.format(widget.food.expiryDate)}",
                            style: const TextStyle(color: Colors.red),
                          )
                        ],
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.food.title,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7A2B93),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${widget.food.quantityAvailable}",
                              style: const TextStyle(fontSize: 20, color: Colors.white),
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Posted on ${dateFormat.format(widget.food.createdAt)}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),

                      const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(widget.food.description),

                      const SizedBox(height: 20),

                      const Text("Pickup Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      SizedBox(
                        height: 200,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(widget.food.latitude, widget.food.longitude),
                            zoom: 15,
                          ),
                          markers: _markers,
                          zoomControlsEnabled: false,
                          onMapCreated: (c) => _controller.complete(c),
                        ),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;

                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please login"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    if (user.uid == widget.food.ownerId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("You cannot request your own food"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    // Unique QR string
                    final String uniqueQrString =
                        "SE-${user.uid.substring(0, 5)}-${DateTime.now().millisecondsSinceEpoch}";

                    final newBooking = BookingModel(
                      id: '',
                      foodId: widget.food.id,
                      foodTitle: widget.food.title,
                      foodImage: widget.food.imageUrl,
                      requesterId: user.uid,
                      ownerId: widget.food.ownerId,
                      status: 'pending',
                      qrCodeData: uniqueQrString,
                      createdAt: DateTime.now(),
                    );

                    final repo = BookingRepository();

                    try {
                      await repo.createBooking(newBooking); // FIXED (no cast)
                      if (context.mounted) Navigator.pop(context);
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
                  child: const Text("Request Food",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
