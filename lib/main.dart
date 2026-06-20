import 'package:bebezen/acceuil.dart';
import 'package:bebezen/admin/login_admin.dart';
import 'package:bebezen/core/services/notification_service.dart';
import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bebezen/services/gemini_service.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!_isAdminPlatform) {
    GeminiService().initialize();
    await NotificationService().initialize();
  }
  runApp(const MyApp());
}

bool get _isAdminPlatform {
  if (kIsWeb) return true;
  return switch (defaultTargetPlatform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => true,
    _ => false,
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bebezen',
      theme: BebezenTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: _isAdminPlatform ? const AdminAccessGate() : const Acceuil3(),
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
