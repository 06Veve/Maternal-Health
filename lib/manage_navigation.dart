import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/core/services/account_service.dart';
import 'package:bebezen/features/partner/couple_chat.dart';
import 'package:bebezen/features/partner/partner_mode.dart';
import 'package:bebezen/home.dart';
import 'package:bebezen/insights.dart';
import 'package:bebezen/messages.dart';
import 'package:bebezen/profile.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageNavigation extends StatefulWidget {
  const ManageNavigation({super.key});

  @override
  State<ManageNavigation> createState() => _ManageNavigationState();
}

class _ManageNavigationState extends State<ManageNavigation> {
  int _currentIndex = 0;
  String? _activeRole;

  void _changePage(int index) {
    if (index == _currentIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: BZLoading());
        if (snapshot.data!.data()?['householdId'] == null) {
          return FutureBuilder<void>(
            future: AccountService().migrateCurrentUserIfNeeded(),
            builder: (context, migration) {
              if (migration.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      'Unable to prepare your family profile: ${migration.error}',
                    ),
                  ),
                );
              }
              return const Scaffold(body: BZLoading());
            },
          );
        }
        final role = snapshot.data!.data()?['role'] as String? ?? 'mother';
        final householdId = snapshot.data!.data()?['householdId'] as String;
        if (_activeRole != role) {
          _activeRole = role;
          _currentIndex = 0;
        }
        final partner = role == 'partner';
        final pages = partner
            ? <Widget>[
                const PartnerDashboard(),
                const PartnerTasksPage(),
                CoupleChatPage(active: _currentIndex == 2),
                const ProfilePage(),
              ]
            : const <Widget>[Home(), Insights(), MessagePage(), ProfilePage()];
        final destinations = partner
            ? <NavigationDestination>[
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.checklist_outlined),
                  selectedIcon: Icon(Icons.checklist_rounded),
                  label: 'Tasks',
                ),
                NavigationDestination(
                  icon: FamilyChatBadge(householdId: householdId),
                  selectedIcon: FamilyChatBadge(
                    householdId: householdId,
                    selected: true,
                  ),
                  label: 'Family',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ]
            : const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Today',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: 'Insights',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: 'Assistant',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ];

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: NavigationBar(
                  height: 68,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _changePage,
                  indicatorColor: BebezenPalette.primaryLight,
                  backgroundColor: Colors.white,
                  destinations: destinations,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
