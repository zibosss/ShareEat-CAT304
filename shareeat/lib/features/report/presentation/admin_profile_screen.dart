import 'package:flutter/material.dart';

import '../../user_registration/data/user_model.dart';
import '../../user_registration/data/user_repository.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final UserRepository _userRepo = UserRepository();

  AppUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _userRepo.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentUser == null) {
      return const Center(child: Text("Admin profile not found"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          // 🔵 Avatar (view only)
          CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFF7A2B93),
            backgroundImage: _currentUser!.profileImageUrl.isNotEmpty
                ? NetworkImage(_currentUser!.profileImageUrl)
                : null,
            child: _currentUser!.profileImageUrl.isEmpty
                ? const Icon(Icons.person, size: 60, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 10),
          const Text(
            "Admin profile (view only)",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 25),

          _sectionTitle("Personal Information"),

          _label("Full Name"),
          _disabled(_currentUser!.fullName),

          _label("Username"),
          _disabled(_currentUser!.username),

          _label("Phone Number"),
          _disabled(_currentUser!.contactNumber),

          _label("Email"),
          _disabled(_currentUser!.email),

          _label("Gender"),
          _disabled(_currentUser!.gender),

          const SizedBox(height: 40),

          _sectionTitle("Account Role"),
          _disabled("Administrator"),
        ],
      ),
    );
  }

  // ================= UI HELPERS =================

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
}
