import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = await _userRepo.getCurrentUserProfile();
    if (user != null) {
      _currentUser = user;
      print("DEBUG >>> Loaded user uid=${user.uid}");
      print("DEBUG >>> profileImageUrl=${user.profileImageUrl}");
    } else {
      print("DEBUG >>> No user profile found in Realtime DB");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("No profile found")),
      );
    }

    final img = _currentUser!.profileImageUrl;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A2B93),
        title: const Text("Profile Debug"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Full name: ${_currentUser!.fullName}"),
            Text("Email: ${_currentUser!.email}"),
            const SizedBox(height: 16),
            const Text(
              "Image URL from DB:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SelectableText(
              img.isEmpty ? "<EMPTY>" : img,
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            const Text(
              "Image preview (Image.network):",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (img.isEmpty)
              const Text(
                "No profileImageUrl stored for this user.",
                style: TextStyle(color: Colors.red),
              )
            else
              Expanded(
                child: Center(
                  child: Image.network(
                    img,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) {
                      print("DEBUG >>> Image.network error: $error");
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 40),
                          const SizedBox(height: 8),
                          const Text(
                            "Failed to load image from URL.",
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
