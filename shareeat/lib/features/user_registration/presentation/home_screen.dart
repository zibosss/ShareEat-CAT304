import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_screen.dart';
import '../data/user_model.dart';
import '../data/user_repository.dart';

// ✅ FIX THESE PATHS to match your real folder:
import '../../food_listing/presentation/food_list_screen.dart';
import '../../food_listing/presentation/add_food_screen.dart';

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

  final GlobalKey<FoodListScreenState> _foodListKey =
      GlobalKey<FoodListScreenState>();

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
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _navigateToAddFood() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFoodScreen()),
    );

    if (result == true) {
      // ✅ go back to Home tab so user can immediately see the new food
      setState(() => _selectedIndex = 0);
      _foodListKey.currentState?.reloadFoods();
    }
  }

  Future<void> _confirmLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log out"),
        content: const Text("Are you sure you want to log out?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

  void _onNavTap(int index) {
    if (index == 1) {
      _navigateToAddFood();
      return;
    }

    setState(() => _selectedIndex = index);

    if (index == 0) {
      _loadCurrentUser();
      _foodListKey.currentState?.reloadFoods();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0 ? _homeAppBar() : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          FoodListScreen(
            key: _foodListKey,
            username: _currentUser?.username,
            isLoadingUser: _isLoadingUser,
          ),
          const SizedBox.shrink(),
          const Center(child: Text("Bookings")), // keep placeholder
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: const BoxDecoration(color: Color(0xFF7A2B93)),
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
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _onNavTap(3),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white24,
                        backgroundImage: (_currentUser != null && _currentUser!.profileImageUrl.isNotEmpty)
                            ? NetworkImage(_currentUser!.profileImageUrl)
                            : null,
                        child: (_currentUser == null || _currentUser!.profileImageUrl.isEmpty)
                            ? const Icon(Icons.person, size: 22, color: Colors.white)
                            : null,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _navButton(IconData icon, int index) {
    final bool isActive = _selectedIndex == index;
    return InkWell(
      onTap: () => _onNavTap(index),
      child: Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 28),
    );
  }
}