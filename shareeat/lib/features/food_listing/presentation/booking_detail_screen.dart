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

  const BookingDetailScreen({super.key, required this.food});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  final UserRepository _userRepo = UserRepository();
  AppUser? _donor;
  bool _isLoadingDonor = true;

  // ✅ STATE FOR QUANTITY SELECTION
  int _requestQty = 1; 

  @override
  void initState() {
    super.initState();
    _setMarker();
    _loadDonorInfo();
  }

  void _setMarker() { /* ... keep existing code ... */ 
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

  Future<void> _loadDonorInfo() async { /* ... keep existing code ... */ 
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
    }
  }

  // ✅ INCREMENT FUNCTION
  void _incrementQty() {
    if (_requestQty < widget.food.quantityAvailable) {
      setState(() => _requestQty++);
    }
  }

  // ✅ DECREMENT FUNCTION
  void _decrementQty() {
    if (_requestQty > 1) {
      setState(() => _requestQty--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final expiryFormat = DateFormat('dd MMM yyyy');
    final bool isOutOfStock = widget.food.quantityAvailable <= 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. APP BAR (Keep same)
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF7A2B93),
                flexibleSpace: FlexibleSpaceBar(
                  background: widget.food.imageUrl != null && widget.food.imageUrl!.isNotEmpty
                      ? Image.network(widget.food.imageUrl!, fit: BoxFit.cover)
                      : Container(color: Colors.grey[300], child: const Icon(Icons.fastfood, size: 80, color: Colors.grey)),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
                ),
              ),

              // 2. CONTENT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.food.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Posted on ${dateFormat.format(widget.food.createdAt)}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      
                      const SizedBox(height: 20),

                      // Info Badges (Halal, Stock, Expiry) - Keep existing code...
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildBadge(widget.food.isHalal ? 'Halal' : 'Non-Halal', widget.food.isHalal ? Colors.green : Colors.orange, widget.food.isHalal ? Icons.check_circle : Icons.warning),
                            const SizedBox(width: 12),
                            _buildBadge(isOutOfStock ? "Out of Stock" : "${widget.food.quantityAvailable} Left", isOutOfStock ? Colors.grey : Colors.blue, Icons.shopping_basket_outlined),
                            const SizedBox(width: 12),
                            _buildBadge(expiryFormat.format(widget.food.expiryDate), Colors.red, Icons.timer_outlined),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      const Divider(),
                      const SizedBox(height: 20),

                      // ✅ QUANTITY SELECTOR
                      if (!isOutOfStock) ...[
                        const Text("Select Quantity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                children: [
                                  IconButton(onPressed: _decrementQty, icon: const Icon(Icons.remove)),
                                  Text("$_requestQty", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  IconButton(onPressed: _incrementQty, icon: const Icon(Icons.add)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Text("Max: ${widget.food.quantityAvailable}", style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(height: 25),
                        const Divider(),
                        const SizedBox(height: 20),
                      ],

                      // Description
                      const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(widget.food.description, style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[800])),

                      const SizedBox(height: 25),

                      // Donor Info & Map (Keep existing...)
                      const Text("Donor Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildDonorInfo(),
                      
                      const SizedBox(height: 25),
                      const Text("Pickup Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      SizedBox(height: 200, child: ClipRRect(borderRadius: BorderRadius.circular(15), child: GoogleMap(initialCameraPosition: CameraPosition(target: LatLng(widget.food.latitude, widget.food.longitude), zoom: 15), markers: _markers, zoomControlsEnabled: false, onMapCreated: (c) => _controller.complete(c)))),
                      
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
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: isOutOfStock ? Colors.grey : const Color(0xFF7A2B93), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: isOutOfStock ? null : _handleRequest,
                  child: Text(isOutOfStock ? "Out of Stock" : "Request $_requestQty Items", style: const TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Badges
  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.5))),
      child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))]),
    );
  }

  // Helper for Donor
  Widget _buildDonorInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.purple.withOpacity(0.1))),
      child: _isLoadingDonor ? const Center(child: CircularProgressIndicator()) : _donor == null ? const Text("Info unavailable") : Row(children: [CircleAvatar(radius: 25, backgroundColor: const Color(0xFF7A2B93), child: Text(_donor!.fullName.isNotEmpty ? _donor!.fullName[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontSize: 20))), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_donor!.fullName, style: const TextStyle(fontWeight: FontWeight.bold)), Text(_donor!.contactNumber)])]),
    );
  }

  // ✅ NEW REQUEST HANDLER
  Future<void> _handleRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login"))); return; }
    if (user.uid == widget.food.ownerId) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot request own food"))); return; }

    final newBooking = BookingModel(
      id: '',
      foodId: widget.food.id,
      foodTitle: widget.food.title,
      foodImage: widget.food.imageUrl,
      requesterId: user.uid,
      ownerId: widget.food.ownerId,
      status: 'pending',
      qrCodeData: "SE-${user.uid.substring(0, 5)}-${DateTime.now().millisecondsSinceEpoch}",
      createdAt: DateTime.now(),
      quantity: _requestQty, // ✅ PASS CHOSEN QUANTITY
    );

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing..."), duration: Duration(milliseconds: 500)));
      await BookingRepository().createBooking(newBooking);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }
}