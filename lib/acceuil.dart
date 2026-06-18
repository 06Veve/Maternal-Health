import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/login.dart';
import 'package:bebezen/manage_navigation.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Acceuil3 extends StatefulWidget {
  const Acceuil3({super.key});

  @override
  State<Acceuil3> createState() => _Acceuil3State();
}

class _Acceuil3State extends State<Acceuil3> {
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRoute();
  }

  Future<void> _checkAuthAndRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool('remember_me') ?? true;
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !remember) {
        await FirebaseAuth.instance.signOut();
      }

      if (user != null && remember) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ManageNavigation()),
        );
      }
    } finally {
      if (mounted) setState(() => _booting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) return const Scaffold(body: BZLoading());

    final loggedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: BebezenPalette.softGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Hero(
                  tag: "logo",
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: BebezenPalette.primary.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        "assets/images/img.png",
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Bebezen",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: BebezenPalette.primary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your maternal health companion\nfor personalized and secure care",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: BebezenPalette.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeatureIcon(Icons.favorite, "Follow-Up"),
                    _buildFeatureIcon(Icons.calendar_today, "Recalls"),
                    _buildFeatureIcon(Icons.medical_services, "Advices"),
                  ],
                ),
                const Spacer(flex: 3),
                BZButton(
                  label: loggedIn ? "Enter App" : "Get Started",
                  onPressed: () {
                    final dest = loggedIn ? const ManageNavigation() : const LoginPage();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => dest));
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  "Secured • Confidential • Professional",
                  style: TextStyle(
                    fontSize: 12,
                    color: BebezenPalette.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        BZCard(
          padding: const EdgeInsets.all(16),
          child: Icon(icon, color: BebezenPalette.primary, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: BebezenPalette.textPrimary,
          ),
        ),
      ],
    );
  }
}
