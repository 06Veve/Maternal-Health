import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/login.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  int _week(Map<String, dynamic> pregnancy) {
    final initial = pregnancy['gestationalAgeWeeks'] as int? ?? 0;
    final reference = pregnancy['referenceDate'] as Timestamp?;
    if (reference == null) return initial;
    return (initial + DateTime.now().difference(reference.toDate()).inDays ~/ 7)
        .clamp(0, 42);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, profileSnapshot) {
          if (!profileSnapshot.hasData) return const BZLoading();
          final profile = profileSnapshot.data!.data() ?? {};
          final householdId = profile['householdId'] as String?;
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: householdId == null
                ? null
                : FirebaseFirestore.instance
                      .collection('households')
                      .doc(householdId)
                      .snapshots(),
            builder: (context, householdSnapshot) {
              final household = householdSnapshot.data?.data() ?? {};
              final pregnancy = Map<String, dynamic>.from(
                household['pregnancy'] as Map? ?? {},
              );
              final role = profile['role'] == 'partner'
                  ? 'Partner account'
                  : 'Mother account';
              final name =
                  profile['name'] ??
                  user.displayName ??
                  user.email?.split('@').first ??
                  'User';
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const CircleAvatar(
                    radius: 48,
                    backgroundColor: BebezenPalette.primaryLight,
                    child: Icon(
                      Icons.person,
                      size: 46,
                      color: BebezenPalette.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    role,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  BZCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Email'),
                          subtitle: Text(user.email ?? ''),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.pregnant_woman),
                          title: const Text('Pregnancy'),
                          subtitle: Text('Week ${_week(pregnancy)}'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.family_restroom),
                          title: const Text('Family link'),
                          subtitle: Text(
                            household['partnerId'] == null
                                ? 'No partner linked'
                                : 'Partner connected',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  BZButton(
                    label: 'Log out',
                    onPressed: () => _signOut(context),
                    isSecondary: true,
                    icon: Icons.logout,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
