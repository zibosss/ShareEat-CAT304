import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'features/user_registration/presentation/welcome_screen.dart';
import 'features/user_registration/presentation/login_screen.dart';
import 'features/user_registration/presentation/registration_screen.dart';
import 'features/user_registration/presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Web needs explicit options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    // Android (and others using native config) – no options
    await Firebase.initializeApp();
  }

  runApp(const ShareEatApp());
}

class ShareEatApp extends StatelessWidget {
  const ShareEatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}