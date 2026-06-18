import 'package:bebezen/acceuil.dart';
import 'package:bebezen/core/services/notification_service.dart';
import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bebezen/services/gemini_service.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Initialize AI
  GeminiService().initialize();

  // Initialize Notifications
  await NotificationService().initialize();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bebezen',
      theme: BebezenTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const Acceuil3(),
    );
  }
}

class Authentication extends StatelessWidget {
  const Authentication({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return Home();
        } else {
          return Acceuil3();
        }
      },
    );
  }
}
