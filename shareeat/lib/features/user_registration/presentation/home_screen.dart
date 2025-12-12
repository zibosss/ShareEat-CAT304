import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_screen.dart';
import '../data/user_model.dart';
import '../data/user_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final UserRepository _userRepo = UserRepository();
  AppUser? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userRepo.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingUser = false);
    }
  }

  // LOGOUT CONFIRMATION
  Future<void> _confirmLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log out"),
        content: const Text("Are you sure you want to log out?"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 209, 202, 211),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Log out"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  // ✅ CENTRAL TAB SWITCH HANDLER
  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);

    // Refresh user data when returning to Home
    if (index == 0) {
      _loadCurrentUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ APPBAR ONLY ON HOME TAB
      appBar: _selectedIndex == 0 ? _homeAppBar() : null,

      // ------------------------------ BODY ------------------------------
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _homeFeed(),
          const Center(child: Text("Add Post")),
          const Center(child: Text("Bookings")),
          const ProfileScreen(),
        ],
      ),

      // ------------------------------ BOTTOM NAV ------------------------------
      bottomNavigationBar: Container(
        height: 65,
        decoration: const BoxDecoration(
          color: Color(0xFF7A2B93),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navButton(Icons.home, 0),
            _navButton(Icons.add_circle_outline, 1),
            _navButton(Icons.book_online, 2),
            _navButton(Icons.person, 3),
          ],
        ),
      ),
    );
  }

  // ------------------------------ HOME APP BAR ------------------------------
  AppBar _homeAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF7A2B93),
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,

      leading: IconButton(
        icon: const Icon(Icons.logout, color: Colors.white),
        onPressed: _confirmLogout,
      ),

      title: const Text(
        "ShareEat",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _isLoadingUser
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  children: [
                    Text(
                      _currentUser?.username ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ✅ FIX: avatar switches to Profile TAB (no Navigator.push)
                    GestureDetector(
                      onTap: () => _onNavTap(3),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white24,
                        backgroundImage:
                            (_currentUser != null &&
                                    _currentUser!.profileImageUrl.isNotEmpty)
                                ? NetworkImage(
                                    _currentUser!.profileImageUrl,
                                  )
                                : null,
                        child: (_currentUser == null ||
                                _currentUser!.profileImageUrl.isEmpty)
                            ? const Icon(
                                Icons.person,
                                size: 22,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ------------------------------ HOME FEED ------------------------------
  Widget _homeFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _isLoadingUser
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi, ${_currentUser?.username ?? ""} 👋",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Ready to share food today?",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 15),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black.withOpacity(0.2)),
            ),
            child: const TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Search...",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),

        const Expanded(
          child: Center(
            child: Text(
              "No food posts available yet",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------ NAV BUTTON ------------------------------
  Widget _navButton(IconData icon, int index) {
    final bool isActive = _selectedIndex == index;

    return InkWell(
      onTap: () => _onNavTap(index),
      child: Icon(
        icon,
        color: isActive ? Colors.white : Colors.white70,
        size: 28,
      ),
    );
  }
}
