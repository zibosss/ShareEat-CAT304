import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),

              Image.asset(
                "assets/images/food.png", // <-- your bowl illustration
                height: 200,
              ),

              const SizedBox(height: 30),

              const Text.rich(
                TextSpan(
                  text: "Hunger waits for\n",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w300),
                  children: [
                    TextSpan(
                      text: "no one.\n",
                      style:
                          TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: "Let’s ",
                      style: TextStyle(fontSize: 34),
                    ),
                    TextSpan(
                      text: "share.",
                      style: TextStyle(
                        fontSize: 34,
                        color: Color(0xFF7A2B93),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              const Text(
                "Sharing good food is now effortless.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _roundedButton(
                    label: "LOG IN",
                    color: Colors.grey.shade300,
                    textColor: Colors.black,
                    onTap: () {
                      Navigator.pushNamed(context, "/login");
                    },
                  ),
                  const SizedBox(width: 15),
                  _roundedButton(
                    label: "REGISTER",
                    color: const Color(0xFF7A2B93),
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.pushNamed(context, "/register");
                    },
                  ),
                ],
              ),

              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundedButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 48,
      width: 120,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onTap,
        child: Text(label, style: TextStyle(color: textColor)),
      ),
    );
  }
}
