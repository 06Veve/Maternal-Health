import 'package:bebezen/calendar.dart';
import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/home_nav_pages/Comm_forum.dart';
import 'package:bebezen/home_nav_pages/Emerg_services.dart';
import 'package:bebezen/home_nav_pages/healthy_tips.dart';
import 'package:bebezen/home_nav_pages/preg_tracker.dart';
import 'package:bebezen/features/partner/couple_chat.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final User? user = FirebaseAuth.instance.currentUser;

  int calculateGestationalAge(Map<String, dynamic> data) {
    final int initialAge = data['gestationalAgeWeeks'] ?? 0;
    final Timestamp? refTs = data['referenceDate'];
    if (refTs == null) return initialAge;
    final int weeksPassed =
        DateTime.now().difference(refTs.toDate()).inDays ~/ 7;
    return (initialAge + weeksPassed).clamp(0, 42);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const BZLoading();
            final profile =
                snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final householdId = profile['householdId'] as String?;
            if (householdId == null) return const BZLoading();
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('households')
                  .doc(householdId)
                  .snapshots(),
              builder: (context, householdSnapshot) {
                if (!householdSnapshot.hasData) return const BZLoading();
                final household =
                    householdSnapshot.data!.data() as Map<String, dynamic>? ??
                    {};
                final pregnancy = Map<String, dynamic>.from(
                  household['pregnancy'] as Map? ?? {},
                );
                final gestationalAge = calculateGestationalAge(pregnancy);
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        context,
                        profile['name'] as String?,
                        householdId,
                      ),
                      const SizedBox(height: 32),
                      if (gestationalAge > 0)
                        _buildBabyProgressCard(gestationalAge),
                      const SizedBox(height: 32),
                      Text(
                        "Quick Actions",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildCardsGrid(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String? profileName,
    String householdId,
  ) {
    final name = profileName ?? user?.email?.split("@")[0] ?? 'User';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, $name! 👋",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              "Let's take care of you today",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        Row(
          children: [
            BZCard(
              padding: const EdgeInsets.all(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CoupleChatPage()),
              ),
              child: FamilyChatBadge(householdId: householdId),
            ),
            const SizedBox(width: 8),
            BZCard(
              padding: const EdgeInsets.all(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PregnancyCalendarPage(),
                ),
              ),
              child: const Icon(
                Icons.calendar_month,
                color: BebezenPalette.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBabyProgressCard(int age) {
    return BZCard(
      color: BebezenPalette.primaryLight,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Week $age",
                    style: const TextStyle(
                      color: BebezenPalette.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your baby is\n$age weeks today! 💕",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            "assets/images/hand-drawn-fetus-illustration.png",
            height: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildCardsGrid() {
    final actions = [
      {
        'icon': Icons.pregnant_woman,
        'title': 'Pregnancy\nTracker',
        'page': PregnancyTrackerPage(),
      },
      {
        'icon': Icons.emergency,
        'title': 'Emergency\nServices',
        'page': const EmergencyServices(),
      },
      {
        'icon': Icons.forum,
        'title': 'Community\nForum',
        'page': const ForumPage(),
      },
      {
        'icon': Icons.favorite,
        'title': 'Healthy\nTips',
        'page': HealthyTipsPage(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) {
        return BZCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => actions[i]['page'] as Widget,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                actions[i]['icon'] as IconData,
                color: BebezenPalette.primary,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                actions[i]['title'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
