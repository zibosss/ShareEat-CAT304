// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../data/food_repository.dart';
import '../data/models/food_model.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final FoodRepository _repository = FoodRepository();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _otherQuantityController = TextEditingController();

  File? _selectedImage;
  int _selectedQuantity = 1;
  bool _isOtherQuantity = false;
  bool _isHalal = true;

  DateTime? _selectedDate;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isMapCreated = false;

  bool _isLoading = false;
  bool _showLocationScreen = false;
  bool _isLoadingLocation = true;

  Future<void> _getCurrentLocation() async {
    if (!_isMapCreated) return;

    try {
      setState(() => _isLoadingLocation = true);

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied. Enable it in settings.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      if (!mounted) return;

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 16));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF7A2B93)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) setState(() => _selectedDate = picked);
  }

  int _getQuantity() {
    if (_isOtherQuantity) return int.tryParse(_otherQuantityController.text) ?? 1;
    return _selectedQuantity;
  }

  void _nextToLocation() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an expiry date'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() {
        _showLocationScreen = true;
        _isLoadingLocation = true;
      });
    }
  }

  Future<String?> _uploadImageToStorage({
    required String uid,
    required File imageFile,
  }) async {
    final fileName = 'food_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref('foods/$uid/$fileName');
    final task = await ref.putFile(imageFile);
    return task.ref.getDownloadURL();
  }

  Future<void> _submitFood() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map'), backgroundColor: Colors.red),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? imageUrl;
    try {
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToStorage(uid: uid, imageFile: _selectedImage!);
      }
    } catch (e) {
      print('Image upload failed: $e');
    }

    final qty = _getQuantity();

    final food = FoodModel(
      id: '',
      ownerId: uid,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      quantity: qty,
      quantityAvailable: qty,
      expiryDate: _selectedDate!,
      isHalal: _isHalal,
      imageUrl: imageUrl,
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      status: 'available',
      createdAt: DateTime.now(), // will be overwritten in Firestore with serverTimestamp
    );

    try {
      await _repository.addFood(food);
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food added successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add food: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7A2B93),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A2B93),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_showLocationScreen) {
              setState(() {
                _showLocationScreen = false;
                _isMapCreated = false;
                _mapController?.dispose();
                _mapController = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Share Food', style: TextStyle(color: Colors.white)),
      ),
      body: _showLocationScreen ? _buildLocationScreen() : _buildFormScreen(),
    );
  }

  // ---------- UI BELOW (same as yours) ----------
  // Kept your UI as-is for form + location screen.

  Widget _buildFormScreen() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF7A2B93), width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 50, color: const Color(0xFF7A2B93).withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text('Add Image', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Title', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF7A2B93)),
                ),
              ),
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter a title' : null,
            ),

            const SizedBox(height: 20),
            const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF7A2B93)),
                ),
              ),
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description' : null,
            ),

            const SizedBox(height: 20),
            const Text('Quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                for (int i = 1; i <= 5; i++)
                  ChoiceChip(
                    label: Text('$i'),
                    selected: !_isOtherQuantity && _selectedQuantity == i,
                    selectedColor: const Color(0xFF7A2B93),
                    labelStyle: TextStyle(
                      color: !_isOtherQuantity && _selectedQuantity == i ? Colors.white : Colors.black,
                    ),
                    onSelected: (_) => setState(() {
                      _isOtherQuantity = false;
                      _selectedQuantity = i;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 120,
              child: TextFormField(
                controller: _otherQuantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Other',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF7A2B93)),
                  ),
                ),
                onChanged: (value) => setState(() => _isOtherQuantity = value.isNotEmpty),
              ),
            ),

            const SizedBox(height: 20),
            const Text('Expiry Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7A2B93),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: Color(0xFF7A2B93)),
              ),
            ),

            const SizedBox(height: 20),
            const Text('Halal Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Halal'),
                    value: true,
                    groupValue: _isHalal,
                    activeColor: const Color(0xFF7A2B93),
                    onChanged: (value) => setState(() => _isHalal = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Non-Halal'),
                    value: false,
                    groupValue: _isHalal,
                    activeColor: const Color(0xFF7A2B93),
                    onChanged: (value) => setState(() => _isHalal = value!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _nextToLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A2B93),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Next', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationScreen() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Pin Your Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Tap on the map to set your exact location',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(5.3479, 100.2878),
                      zoom: 16,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _isMapCreated = true;

                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted && _isMapCreated) _getCurrentLocation();
                      });
                    },
                    onTap: (pos) => setState(() => _selectedLocation = pos),
                    markers: _selectedLocation != null
                        ? {
                            Marker(
                              markerId: const MarkerId('selected_location'),
                              position: _selectedLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                            ),
                          }
                        : {},
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                  if (_isLoadingLocation)
                    Container(
                      color: Colors.white.withOpacity(0.7),
                      child: const Center(child: CircularProgressIndicator(color: Color(0xFF7A2B93))),
                    ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _isMapCreated ? _getCurrentLocation : null,
                      child: const Icon(Icons.my_location, color: Color(0xFF7A2B93)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitFood,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A2B93),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _otherQuantityController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}