import 'package:bebezen/calendar.dart';
import 'package:bebezen/custom_widget/HomeCard.dart';
import 'package:bebezen/custom_widget/sos_button.dart';
import 'package:bebezen/home_nav_pages/Comm_forum.dart';
import 'package:bebezen/home_nav_pages/Emerg_services.dart';
import 'package:bebezen/home_nav_pages/healthy_tips.dart';
import 'package:bebezen/home_nav_pages/preg_tracker.dart';
import 'package:bebezen/login.dart';
import 'package:bebezen/signup2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ---- LOGIC ----
  int calculateGestationalAge(Map<String, dynamic> data) {
    final int initialAge = data['gestationalAgeWeeks'] ?? 0;
    final Timestamp? refTs = data['gestationalReferenceDate'];
    if (refTs == null) return initialAge;

    final DateTime refDate = refTs.toDate();
    final int weeksPassed = DateTime.now().difference(refDate).inDays ~/ 7;

    return (initialAge + weeksPassed).clamp(0, 42); // cap at 42 weeks
  }

  DateTime? calculateDueDate(Map<String, dynamic> data) {
    final Timestamp? lmpTs = data['pregnancy']?['lmpEstimated'];
    if (lmpTs == null) return null;
    return lmpTs.toDate().add(const Duration(days: 280)); // 40 weeks
  }

  /// ---- MAIN BUILD ----
  @override
  Widget build(BuildContext context) {
    Future<void> signout(BuildContext context) async {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3F7),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.pinkAccent),
                ),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final gestationalAge = calculateGestationalAge(data);
            print("AGE 😐😐😐😐😐😐😐😐😐😐 $gestationalAge");

            return SingleChildScrollView(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(context),
                    const SizedBox(height: 24),

                    // Baby Progress (Firestore driven!)
                    if (gestationalAge > 0)
                      _buildBabyProgressCard(gestationalAge),
                    const SizedBox(height: 28),

                    // Section Title
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grid
                    _buildCardsGrid(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
        child: SOSButton(onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency message has been sent'),
              duration: Duration(seconds: 2),
            ),
          );
        }),
      ),
    );
  }

  /// ---- UI HELPERS ----
  Widget _buildHeader(context) {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hey , ${user?.email?.split("@")[0] ?? 'User'}! 👋",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Welcome back!",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PregnancyCalendarPage()),
                  );
                },
                icon: const Icon(Icons.calendar_month,
                    color: Colors.pinkAccent, size: 24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Let's take care of you and your baby",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildBabyProgressCard(int gestationalAge) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE0E6), Color(0xFFFFD9D6)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Week $gestationalAge",
                    style: const TextStyle(
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your baby is\n $gestationalAge weeks today! 💕",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Color(0xFF2D2D2D),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Baby is growing beautifully",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage(
                      "assets/images/hand-drawn-fetus-illustration.png"),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsGrid() {
    final cards = [
      {
        'icon': Icons.pregnant_woman_outlined,
        'title': 'Pregnancy\nTracker',
        'color': Colors.purple.shade100
      },
      {
        'icon': Icons.emergency_rounded,
        'title': ' Emergency\nServices',
        'color': Colors.red.shade100
      },
      {
        'icon': Icons.forum_rounded,
        'title': 'Community\nForum',
        'color': Colors.blue.shade100
      },
      {
        'icon': Icons.favorite_rounded,
        'title': 'Healthy\nTips',
        'color': Colors.pink.shade100
      },
    ];

    void _navigateToPage(BuildContext context, int index, String title) {
      switch (index) {
        case 0:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PregnancyTrackerPage()),
          );
          break;
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EmergencyServices()),
          );
          break;
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ForumPage()),
          );
          break;
        case 3:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HealthyTipsPage()),
          );
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title coming soon!')),
          );
      }
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Homecard(
          icon: card['icon'] as IconData,
          title: card['title'] as String,
          color: card['color'] as Color,
          onTap: () => _navigateToPage(context, index, card['title'] as String),
        );
      },
    );
  }
}
