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