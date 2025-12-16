// lib/features/user_registration/presentation/login_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../data/user_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _userRepo = UserRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Log In Here",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7A2B93),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Welcome back",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 40),

                _inputField(
                  "Email",
                  emailController,
                  validator: (v) =>
                      v == null || !v.contains("@") ? "Invalid email" : null,
                ),
                _inputField(
                  "Password",
                  passwordController,
                  isPassword: true,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Password required" : null,
                ),

                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _showForgotPasswordDialog,
                    child: Text(
                      "Forgot your password?",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A2B93),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: _isLoading ? null : _onLoginPressed,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            "LOG IN",
                            style: TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator: validator,
        decoration: InputDecoration(
          hintText: label,
          filled: true,
          fillColor: const Color(0xFFE6E6E6),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _userRepo.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful")),
      );

      Navigator.pushReplacementNamed(context, '/home');

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🔥 FORGOT PASSWORD DIALOG
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reset Password"),
          content: TextField(
            controller: resetEmailController,
            decoration: const InputDecoration(
              hintText: "Enter your email",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final email = resetEmailController.text.trim();

                if (email.isEmpty || !email.contains("@")) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please enter a valid email address")),
                  );
                  return;
                }

                try {
                  await _userRepo.resetPassword(email);

                  if (!mounted) return;

                  
                  Navigator.pop(context);

                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Password reset email sent to $email")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to send reset email: $e")),
                  );
                }
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }
}
