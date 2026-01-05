/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:shareeat/features/user_registration/data/user_repository.dart';
import 'package:shareeat/features/report/presentation/admin_dashboard.dart';
import 'package:shareeat/features/user_registration/presentation/home_screen.dart';

class TempLoginHelper extends StatefulWidget {
  const TempLoginHelper({super.key});

  @override
  State<TempLoginHelper> createState() => _TempLoginHelperState();
}

class _TempLoginHelperState extends State<TempLoginHelper> {
  final _formKey = GlobalKey<FormState>();
  // ignore: unused_field
  bool _isLoading = false;

  final UserRepository _userRepo = UserRepository();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ignore: unused_element
  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Login
      await _userRepo.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 🔍 DEBUG: check which account actually logged in
      final current = FirebaseAuth.instance.currentUser;
      debugPrint("LOGGED IN UID = ${current?.uid}");
      debugPrint("LOGGED IN EMAIL = ${current?.email}");

      // 🔍 DEBUG: check role read from Firestore
      final role = await _userRepo.getCurrentUserRole();
      debugPrint("ROLE FROM FIRESTORE = [$role]");

      if (!mounted) return;

      // 2️⃣ Route based on role
      if (role.trim().toLowerCase() == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().replaceAll("Exception: ", "");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Not used, just here so the file compiles.
    return const SizedBox.shrink();
  }
}
