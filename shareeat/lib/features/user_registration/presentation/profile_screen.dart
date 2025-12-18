import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/user_model.dart';
import '../data/user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserRepository _userRepo = UserRepository();

  AppUser? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;

  Uint8List? _newProfileImageBytes;

  // Controllers
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = await _userRepo.getCurrentUserProfile();
      if (!mounted) return;

      if (user == null) {
        _currentUser = null;
        _showMsg("No profile found. Please log in again.");
        return;
      }

      _currentUser = user;
      fullNameController.text = user.fullName;
      usernameController.text = user.username;
      phoneController.text = user.contactNumber;
    } catch (e) {
      if (mounted) {
        _showMsg("Failed to load profile. Please try again.");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      _newProfileImageBytes = await file.readAsBytes();
      setState(() {});
    }
  }

  Future<void> _changePassword() async {
    final newPass = passwordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showMsg("Please fill in both password fields.");
      return;
    }
    if (newPass != confirmPass) {
      _showMsg("Passwords do not match.");
      return;
    }
    if (newPass.length < 6) {
      _showMsg("Password must be at least 6 characters.");
      return;
    }

    try {
      await FirebaseAuth.instance.currentUser!.updatePassword(newPass);
      passwordController.clear();
      confirmPasswordController.clear();
      _showMsg("Password updated successfully!");
    } catch (e) {
      _showMsg("Failed to change password: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) {
      _showMsg("No profile to save.");
      return;
    }
    setState(() => _isSaving = true);

    try {
      String imageUrl = _currentUser!.profileImageUrl;

      if (_newProfileImageBytes != null) {
        final uid = _currentUser!.uid;
        final storageRef =
            _userRepo.storage.ref().child("user_profiles/$uid/profile.jpg");
        await storageRef.putData(_newProfileImageBytes!);
        imageUrl = await storageRef.getDownloadURL();
      }

      final updatedUser = AppUser(
        uid: _currentUser!.uid,
        fullName: fullNameController.text.trim(),
        username: usernameController.text.trim(),
        email: _currentUser!.email,
        contactNumber: phoneController.text.trim(),
        gender: _currentUser!.gender,
        profileImageUrl: imageUrl,
      );

      await _userRepo.updateUserProfile(updatedUser);

      _showMsg("Profile updated successfully!");
    } catch (e) {
      _showMsg("Failed to save profile: $e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If no profile found
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF7A2B93),
          title: const Text("My Profile"),
          automaticallyImplyLeading: false, // ✅ removed back button
        ),
        body: const Center(
          child: Text(
            "No profile found.\nPlease log out and log in again.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A2B93),
        title: const Text("My Profile"),
        centerTitle: true,
        automaticallyImplyLeading: false, // ✅ removed back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF7A2B93),
                backgroundImage: _newProfileImageBytes != null
                    ? MemoryImage(_newProfileImageBytes!)
                    : (_currentUser!.profileImageUrl.isNotEmpty
                        ? NetworkImage(_currentUser!.profileImageUrl)
                        : null),
                child: (_newProfileImageBytes == null &&
                        _currentUser!.profileImageUrl.isEmpty)
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Tap to change profile picture",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 25),

            _sectionTitle("Personal Information"),
            _label("Full Name"),
            _field(fullNameController),

            _label("Username"),
            _field(usernameController),

            _label("Phone Number"),
            _field(phoneController),

            _label("Email (not editable)"),
            _disabled(_currentUser!.email),

            _label("Gender (not editable)"),
            _disabled(_currentUser!.gender),

            const SizedBox(height: 30),

            _sectionTitle("Change Password"),
            _label("New Password"),
            _field(passwordController, isPassword: true),

            _label("Confirm New Password"),
            _field(confirmPasswordController, isPassword: true),

            const SizedBox(height: 10),
            _purpleButton("UPDATE PASSWORD", _changePassword),

            const SizedBox(height: 35),

            _purpleButton(
              "SAVE PROFILE CHANGES",
              _saveProfile,
              loading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7A2B93),
          ),
        ),
      ),
    );
  }

  Widget _label(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 5),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }

  Widget _field(TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE6E6E6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }

  Widget _disabled(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(text),
    );
  }

  Widget _purpleButton(String label, VoidCallback onTap,
      {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7A2B93),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
