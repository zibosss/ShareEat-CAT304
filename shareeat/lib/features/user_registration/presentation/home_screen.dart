import 'package:flutter/material.dart';
import 'profile_screen.dart';  // 👈 Make sure this path is correct

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);

    if (index == 3) {
      // 👤 Profile Button
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }

    // You can add other navigation later:
    // if (index == 1) => Add Post
    // if (index == 2) => My Bookings / History
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ------------------------------ HEADER ------------------------------
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A2B93),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "YOUR FOOD DONATION PLATFORM",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ------------------------------ BODY ------------------------------
      body: Column(
        children: [
          const SizedBox(height: 15),

          // SEARCH BAR
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

          // EMPTY STATE
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.fastfood_outlined, size: 55, color: Colors.grey),
                  SizedBox(height: 15),
                  Text(
                    "No food posts available yet",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Users will see food items here once they upload.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  // bottom nav button
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
