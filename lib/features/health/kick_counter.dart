import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class KickCounter extends StatefulWidget {
  const KickCounter({super.key});

  @override
  State<KickCounter> createState() => _KickCounterState();
}

class _KickCounterState extends State<KickCounter> {
  int _count = 0;
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  void _startSession() {
    setState(() {
      _count = 0;
      _seconds = 0;
      _isRunning = true;
    });
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (t) => setState(() => _seconds++),
    );
  }

  void _stopSession() async {
    _timer?.cancel();
    setState(() => _isRunning = false);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _count > 0) {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final householdId = profile.data()?['householdId'] as String?;
      if (householdId == null) {
        return;
      }
      await FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .collection('kickSessions')
          .add({
            'count': _count,
            'durationSeconds': _seconds,
            'createdBy': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Kick session saved!")));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kick Counter"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}",
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: BebezenPalette.primary,
              ),
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: () {
                if (_isRunning) setState(() => _count++);
              },
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: BebezenPalette.primary.withValues(alpha: 0.1),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 60,
                      color: BebezenPalette.primary,
                    ),
                    Text(
                      "$_count",
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "KICKS",
                      style: TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 64),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: BZButton(
                label: _isRunning ? "Stop & Save" : "Start Session",
                onPressed: _isRunning ? _stopSession : _startSession,
                isSecondary: _isRunning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
