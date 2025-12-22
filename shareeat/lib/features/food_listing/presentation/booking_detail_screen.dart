import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'package:shareeat/features/food_listing/data/booking_repository.dart';
import 'package:shareeat/features/food_listing/data/models/food_model.dart';
import 'package:shareeat/features/food_listing/data/data/models/booking_model.dart';
import 'package:shareeat/features/user_registration/data/user_model.dart';
import 'package:shareeat/features/user_registration/data/user_repository.dart';

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

  final UserRepository _userRepo = UserRepository();
  AppUser? _donor;
  bool _isLoadingDonor = true;

  @override
  void initState() {
    super.initState();
    _setMarker();
    _loadDonorInfo();
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

  Future<void> _loadDonorInfo() async {
    try {
      AppUser? donor = await _userRepo.getUserById(widget.food.ownerId);
      if (mounted) {
        setState(() {
          _donor = donor;
          _isLoadingDonor = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDonor = false);
      debugPrint("Error loading donor: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final expiryFormat = DateFormat('dd MMM yyyy');

    // Check if food is already out of stock (for UI display only)
    final bool isOutOfStock = widget.food.quantityAvailable <= 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. APP BAR IMAGE
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF7A2B93),
                flexibleSpace: FlexibleSpaceBar(
                  background: widget.food.imageUrl != null &&
                          widget.food.imageUrl!.isNotEmpty
                      ? Image.network(
                          widget.food.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.fastfood, size: 80, color: Colors.grey),
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

              // 2. CONTENT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITLE
                      Text(
                        widget.food.title,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Posted on ${dateFormat.format(widget.food.createdAt)}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),

                      const SizedBox(height: 20),

                      // --- INFO ROW ---
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Halal Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: widget.food.isHalal ? Colors.green[50] : Colors.orange[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: widget.food.isHalal ? Colors.green : Colors.orange),
                              ),
                              child: Row(
                                children: [
                                  Icon(widget.food.isHalal ? Icons.check_circle : Icons.warning, 
                                      size: 16, 
                                      color: widget.food.isHalal ? Colors.green : Colors.orange),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.food.isHalal ? 'Halal' : 'Non-Halal',
                                    style: TextStyle(
                                      color: widget.food.isHalal ? Colors.green[700] : Colors.orange[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 12),

                            // Quantity Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isOutOfStock ? Colors.grey[200] : Colors.blue[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isOutOfStock ? Colors.grey : Colors.blue.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.shopping_basket_outlined, size: 18, color: isOutOfStock ? Colors.grey : Colors.blue),
                                  const SizedBox(width: 6),
                                  Text(
                                    isOutOfStock ? "Out of Stock" : "${widget.food.quantityAvailable} Left",
                                    style: TextStyle(
                                      color: isOutOfStock ? Colors.grey[600] : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Expiry Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 18, color: Colors.red),
                                  const SizedBox(width: 6),
                                  Text(
                                    expiryFormat.format(widget.food.expiryDate),
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                      const Divider(),
                      const SizedBox(height: 20),

                      // DESCRIPTION
                      const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        widget.food.description,
                        style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[800]),
                      ),

                      const SizedBox(height: 25),
                      const Divider(),
                      const SizedBox(height: 20),

                      // DONOR INFORMATION
                      const Text("Donor Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.purple.withOpacity(0.1)),
                        ),
                        child: _isLoadingDonor
                            ? const Center(child: CircularProgressIndicator())
                            : _donor == null
                                ? const Row(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.grey),
                                      SizedBox(width: 10),
                                      Text("Donor information unavailable", style: TextStyle(color: Colors.grey)),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor: const Color(0xFF7A2B93),
                                        child: Text(
                                          (_donor!.fullName.isNotEmpty) ? _donor!.fullName[0].toUpperCase() : "?",
                                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _donor!.fullName,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone, size: 14, color: Colors.grey),
                                                const SizedBox(width: 5),
                                                Text(
                                                  (_donor!.contactNumber.isNotEmpty) ? _donor!.contactNumber : "No contact info",
                                                  style: TextStyle(color: Colors.grey[700]),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                      ),

                      const SizedBox(height: 25),

                      // MAP
                      const Text("Pickup Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
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
                      ),
                      
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. REQUEST BUTTON
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // Change color if out of stock
                    backgroundColor: isOutOfStock ? Colors.grey : const Color(0xFF7A2B93),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isOutOfStock ? null : () async {
                    final user = FirebaseAuth.instance.currentUser;

                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login"), backgroundColor: Colors.red));
                      return;
                    }
                    if (user.uid == widget.food.ownerId) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You cannot request your own food"), backgroundColor: Colors.red));
                      return;
                    }

                    // Generate QR
                    final String uniqueQrString = "SE-${user.uid.substring(0, 5)}-${DateTime.now().millisecondsSinceEpoch}";

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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Processing Request..."), duration: Duration(milliseconds: 500)),
                      );

                      // ✅ This now also deducts the quantity in Firebase!
                      await repo.createBooking(newBooking);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Request Successful!"),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      // ❌ Handle Out of Stock or other errors
                      if (context.mounted) {
                        String errorMsg = e.toString();
                        if (errorMsg.contains("out of stock")) {
                          errorMsg = "Failed: This item is now out of stock.";
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: Text(
                    isOutOfStock ? "Out of Stock" : "Request Food", 
                    style: const TextStyle(fontSize: 18, color: Colors.white)
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