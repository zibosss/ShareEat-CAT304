import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'auth_prefs.dart';

import 'features/user_registration/presentation/welcome_screen.dart';
import 'features/user_registration/presentation/home_screen.dart';
import 'features/user_registration/presentation/login_screen.dart';
import 'features/user_registration/presentation/registration_screen.dart';

import 'features/user_registration/data/user_repository.dart';
import 'features/user_registration/data/user_model.dart';
import 'features/report/presentation/admin_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: kIsWeb ? DefaultFirebaseOptions.currentPlatform : null,
  );

  final keepLoggedIn = await AuthPrefs.getKeepLoggedIn();
  if (!keepLoggedIn) {
    await FirebaseAuth.instance.signOut();
  }

  runApp(const ShareEatApp());
}

class ShareEatApp extends StatelessWidget {
  const ShareEatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegistrationScreen(),
        '/home': (_) => const HomeScreen(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final firebaseUser = snapshot.data;

          if (firebaseUser == null) {
            return const WelcomeScreen();
          }

          return FutureBuilder<AppUser?>(
            future: UserRepository().getCurrentUserProfile(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final appUser = userSnapshot.data;
              final role = appUser?.role.trim().toLowerCase() ?? "user";
              final isBanned = appUser?.isBanned == true;

              if (isBanned) {
                // Safety: if banned, force logout and send to WelcomeScreen
                Future.microtask(() async {
                  await AuthPrefs.setKeepLoggedIn(false);
                  await FirebaseAuth.instance.signOut();
                });
                return const WelcomeScreen();
              }

              if (role == "admin") {
                return const AdminDashboard();
              }

              return const HomeScreen();
            },
          );
        },
      ),
    );
  }
}
