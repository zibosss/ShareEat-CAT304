import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

// Food & Booking
import 'package:shareeat/features/food_listing/data/booking_repository.dart';
import 'package:shareeat/features/food_listing/data/data/models/booking_model.dart';
import 'package:shareeat/features/food_listing/data/models/food_model.dart';

// User module (existing)
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

  // Donor state
  final UserRepository _userRepo = UserRepository();
  AppUser? donor;
  bool isLoadingDonor = true;

  @override
  void initState() {
    super.initState();
    _setMarker();
    _loadDonor();
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
  }

  Future<void> _loadDonor() async {
    donor = await _userRepo.getUserById(widget.food.ownerId);
    if (!mounted) return;
    setState(() => isLoadingDonor = false);
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
              // APP BAR IMAGE
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
                          errorBuilder: (_, __, ___) =>
                              Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.fastfood, size: 80),
                        ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // CONTENT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Halal & Expiry
                      Row(
                        children: [
                          Chip(
                            label: Text(widget.food.isHalal ? 'Halal' : 'Non-Halal'),
                            backgroundColor:
                                widget.food.isHalal ? Colors.green[50] : Colors.orange[50],
                          ),
                          const Spacer(),
                          Text(
                            "Expires: ${expiryFormat.format(widget.food.expiryDate)}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Title
                      Text(
                        widget.food.title,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),

                      Text(
                        "Posted on ${dateFormat.format(widget.food.createdAt)}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),

                      const SizedBox(height: 20),
                      const Divider(),

                      // Description
                      const Text(
                        "Description",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.food.description),

                      const SizedBox(height: 20),
                      const Divider(),

                      // DONOR INFO
                      const Text(
                        "Donor Information",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      if (isLoadingDonor)
                        const Center(child: CircularProgressIndicator())
                      else if (donor != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  donor!.username,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  donor!.contactNumber,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        const Text(
                          "Donor information not available",
                          style: TextStyle(color: Colors.grey),
                        ),

                      const SizedBox(height: 20),
                      const Divider(),

                      // Location
                      const Text(
                        "Pickup Location",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
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

          // REQUEST BUTTON
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A2B93),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Request Food", style: TextStyle(fontSize: 18)),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null || user.uid == widget.food.ownerId) return;

                  final booking = BookingModel(
                    id: '',
                    foodId: widget.food.id,
                    foodTitle: widget.food.title,
                    foodImage: widget.food.imageUrl,
                    requesterId: user.uid,
                    ownerId: widget.food.ownerId,
                    status: 'pending',
                    qrCodeData:
                        "SE-${user.uid.substring(0, 5)}-${DateTime.now().millisecondsSinceEpoch}",
                    createdAt: DateTime.now(),
                  );

                  await BookingRepository().createBooking(booking);
                  if (mounted) Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
