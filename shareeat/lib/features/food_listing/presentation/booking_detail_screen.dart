import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

// ✅ CORRECT IMPORTS (Adjust if your paths are different)
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

  // ✅ DONOR STATE
  final UserRepository _userRepo = UserRepository();
  AppUser? _donor;
  bool _isLoadingDonor = true;

  @override
  void initState() {
    super.initState();
    _setMarker();
    _loadDonorInfo(); // Load donor when screen opens
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

  // ✅ FETCH DONOR LOGIC
  Future<void> _loadDonorInfo() async {
    try {
      // Calls the function in UserRepository
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
                expandedHeight: 250,
                pinned: true,
                backgroundColor: const Color(0xFF7A2B93),
                flexibleSpace: FlexibleSpaceBar(
                  background: widget.food.imageUrl != null &&
                          widget.food.imageUrl!.isNotEmpty
                      ? Image.network(
                          widget.food.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
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

              // 2. CONTENT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Halal Tag & Expiry
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
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                          )
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Title
                      Text(
                        widget.food.title,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 5),
                      Text(
                        "Posted on ${dateFormat.format(widget.food.createdAt)}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Description
                      const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(widget.food.description, style: const TextStyle(fontSize: 15, height: 1.5)),

                      const SizedBox(height: 25),
                      const Divider(),
                      const SizedBox(height: 25),

                      // ✅ DONOR INFORMATION SECTION
                      const Text("Donor Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple[50], // Light purple background
                          borderRadius: BorderRadius.circular(12),
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
                                      // Avatar
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor: const Color(0xFF7A2B93),
                                        child: Text(
                                          // Use fullName or username based on your User Model
                                          (_donor!.fullName.isNotEmpty) 
                                              ? _donor!.fullName[0].toUpperCase() 
                                              : "?",
                                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      
                                      // Name & Phone
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _donor!.fullName, // Or _donor!.username
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone, size: 14, color: Colors.grey),
                                                const SizedBox(width: 5),
                                                Text(
                                                  (_donor!.contactNumber.isNotEmpty) 
                                                      ? _donor!.contactNumber 
                                                      : "No contact info",
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

                      // Map
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

          // 3. REQUEST BUTTON (Robust Logic)
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
                    backgroundColor: const Color(0xFF7A2B93),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;

                    // Validation checks
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
                      // Processing Message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Sending request..."), duration: Duration(milliseconds: 500)),
                      );

                      await repo.createBooking(newBooking);

                      if (context.mounted) {
                        // ✅ GREEN SUCCESS MESSAGE
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Request sent successfully!"),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                      }
                    }
                  },
                  child: const Text("Request Food", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}