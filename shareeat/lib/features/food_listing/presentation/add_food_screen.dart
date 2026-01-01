// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../data/food_repository.dart';
import '../data/models/food_model.dart';

class AddFoodScreen extends StatefulWidget {
  final FoodModel? food; // ✅ null = add, not null = edit

  const AddFoodScreen({super.key, this.food});

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
  String? _existingImageUrl; // ✅ for edit preview if no new image picked

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

  bool get _isEdit => widget.food != null;

  final LatLng _usmCenter = const LatLng(5.3574, 100.2987);
  final double _usmRadiusMeters = 1500;
  Set<Circle> _usmCircles = {};

  @override
  void initState() {
    super.initState();

    _usmCircles = {
      Circle(
        circleId: const CircleId('usm_radius'),
        center: _usmCenter,
        radius: _usmRadiusMeters,
        strokeWidth: 2,
        strokeColor: const Color(0xFF7A2B93),
        fillColor: const Color(0xFF7A2B93).withOpacity(0.12),
      ),
    };

    // ✅ Prefill if edit mode
    final food = widget.food;
    if (food != null) {
      _titleController.text = food.title;
      _descriptionController.text = food.description;
      _isHalal = food.isHalal;
      _selectedDate = food.expiryDate;
      _selectedLocation = LatLng(food.latitude, food.longitude);
      _existingImageUrl = food.imageUrl;

      final q = food.quantity;
      if (q >= 1 && q <= 5) {
        _selectedQuantity = q;
        _isOtherQuantity = false;
        _otherQuantityController.clear();
      } else {
        _isOtherQuantity = true;
        _otherQuantityController.text = q.toString();
      }
    }
  }

  LatLngBounds _boundsFromCenter(LatLng center, double radiusMeters) {
    final lat = center.latitude;
    final lng = center.longitude;

    final dLat = radiusMeters / 111320.0;
    final dLng = radiusMeters / (111320.0 * math.cos(lat * math.pi / 180));

    final south = lat - dLat;
    final north = lat + dLat;
    final west = lng - dLng;
    final east = lng + dLng;

    return LatLngBounds(
      southwest: LatLng(
        south < north ? south : north,
        west < east ? west : east,
      ),
      northeast: LatLng(
        south > north ? south : north,
        west > east ? west : east,
      ),
    );
  }

  Future<void> _onTapMapRestricted(LatLng pos) async {
    final dist = Geolocator.distanceBetween(
      _usmCenter.latitude,
      _usmCenter.longitude,
      pos.latitude,
      pos.longitude,
    );

    if (dist > _usmRadiusMeters) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location must be within USM Main Campus area.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _selectedLocation = pos);
  }

  Future<void> _getCurrentLocation() async {
    if (!_isMapCreated) return;

    try {
      setState(() => _isLoadingLocation = true);

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services'),
              backgroundColor: Colors.red,
            ),
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

      final dist = Geolocator.distanceBetween(
        _usmCenter.latitude,
        _usmCenter.longitude,
        position.latitude,
        position.longitude,
      );

      if (dist > _usmRadiusMeters) {
        setState(() => _isLoadingLocation = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are outside USM campus radius.'),
            backgroundColor: Colors.red,
          ),
        );

        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_usmCenter, 14));
        return;
      }

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
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (_selectedDate ?? DateTime.now()).add(const Duration(days: 1)),
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

  int getQuantity() {
    if (_isOtherQuantity) return int.tryParse(_otherQuantityController.text) ?? 1;
    return _selectedQuantity;
  }

  void nextToLocation() {
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

  Future<String?> uploadImageToStorage({
    required String uid,
    required File imageFile,
  }) async {
    final fileName = 'food_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref('foods/$uid/$fileName');
    final task = await ref.putFile(imageFile);
    return task.ref.getDownloadURL();
  }

  Future<void> _submitOrUpdate() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map'), backgroundColor: Colors.red),
      );
      return;
    }

    final dist = Geolocator.distanceBetween(
      _usmCenter.latitude,
      _usmCenter.longitude,
      _selectedLocation!.latitude,
      _selectedLocation!.longitude,
    );
    if (dist > _usmRadiusMeters) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected location is outside USM campus area.'), backgroundColor: Colors.red),
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

    // ✅ If editing, ensure same owner edits it
    if (_isEdit && widget.food!.ownerId != uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not allowed to edit this item.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    // ✅ Keep old image unless user picked new one
    String? finalImageUrl = _existingImageUrl;
    try {
      if (_selectedImage != null) {
        finalImageUrl = await uploadImageToStorage(uid: uid, imageFile: _selectedImage!);
      }
    } catch (e) {
      print('Image upload failed: $e');
    }

    final newQty = getQuantity();

    try {
      if (!_isEdit) {
        // ✅ ADD
        final food = FoodModel(
          id: '',
          ownerId: uid,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          quantity: newQty,
          quantityAvailable: newQty,
          expiryDate: _selectedDate!,
          isHalal: _isHalal,
          imageUrl: finalImageUrl,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          status: 'available',
          createdAt: DateTime.now(),
        );

        await _repository.addFood(food);

        if (!mounted) return;
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food added successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        // ✅ EDIT
        final old = widget.food!;

        // Keep booked amount safe:
        // booked = old.quantity - old.quantityAvailable
        final booked = (old.quantity - old.quantityAvailable);
        int newAvailable = newQty - booked;
        if (newAvailable < 0) newAvailable = 0;

        // ⚠️ Requires FoodModel.copyWith()
        final updatedFood = old.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          quantity: newQty,
          quantityAvailable: newAvailable,
          expiryDate: _selectedDate!,
          isHalal: _isHalal,
          imageUrl: finalImageUrl,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
        );

        await _repository.updateFood(updatedFood);

        if (!mounted) return;
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Failed to update food: $e' : 'Failed to add food: $e'), backgroundColor: Colors.red),
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
        title: Text(_isEdit ? 'Edit Food' : 'Share Food', style: const TextStyle(color: Colors.white)),
      ),
      body: _showLocationScreen ? buildLocationScreen() : buildFormScreen(),
    );
  }

  Widget buildFormScreen() {
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
                    : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              _existingImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _emptyImagePlaceholder(),
                            ),
                          )
                        : _emptyImagePlaceholder(),
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
                      _otherQuantityController.clear();
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
              onPressed: selectDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _selectedDate == null ? 'Select Date' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
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
              onPressed: nextToLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A2B93),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_isEdit ? 'Next (Update Location)' : 'Next', style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 50, color: const Color(0xFF7A2B93).withOpacity(0.5)),
        const SizedBox(height: 8),
        Text(_isEdit ? 'Change Image (Optional)' : 'Add Image', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
      ],
    );
  }

  Widget buildLocationScreen() {
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
                Text(
                  'Tap on the map to set your exact location',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation ?? _usmCenter,
                      zoom: 16,
                    ),
                    cameraTargetBounds: CameraTargetBounds(
                      _boundsFromCenter(_usmCenter, _usmRadiusMeters),
                    ),
                    minMaxZoomPreference: const MinMaxZoomPreference(15, 20),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _isMapCreated = true;

                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (!mounted || !_isMapCreated) return;

                        // If editing and already has location, keep it
                        if (_selectedLocation != null) {
                          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 16));
                          setState(() => _isLoadingLocation = false);
                        } else {
                          _getCurrentLocation();
                        }
                      });
                    },
                    onTap: _onTapMapRestricted,
                    markers: _selectedLocation != null
                        ? {
                            Marker(
                              markerId: const MarkerId('selected_location'),
                              position: _selectedLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                            ),
                          }
                        : {},
                    circles: _usmCircles,
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
              onPressed: _isLoading ? null : _submitOrUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A2B93),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isEdit ? 'Update' : 'Submit', style: const TextStyle(fontSize: 16, color: Colors.white)),
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
