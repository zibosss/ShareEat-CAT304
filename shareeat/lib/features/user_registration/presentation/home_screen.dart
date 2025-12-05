import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

          // EMPTY STATE (No food posts yet)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.fastfood_outlined,
                    size: 55,
                    color: Colors.grey,
                  ),
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
            _navButton(Icons.home, true),
            _navButton(Icons.add_circle_outline, false),
            _navButton(Icons.book_online, false),
            _navButton(Icons.person, false),
          ],
        ),
      ),
    );
  }

  // bottom nav button
  Widget _navButton(IconData icon, bool active) {
    return Icon(
      icon,
      color: active ? Colors.white : Colors.white70,
      size: 28,
    );
  }
}
