import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PregnancyTrackerPage extends StatefulWidget {
  const PregnancyTrackerPage({super.key});

  @override
  State<PregnancyTrackerPage> createState() => _PregnancyTrackerPageState();
}

class _PregnancyTrackerPageState extends State<PregnancyTrackerPage>
    with TickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  /// ---- LOGIC ----
  int calculateGestationalAge(Map<String, dynamic> data) {
    final int initialAge = data['gestationalAgeWeeks'] ?? 0;
    final Timestamp? refTs = data['gestationalReferenceDate'];
    if (refTs == null) return initialAge;

    final DateTime refDate = refTs.toDate();
    final int weeksPassed = DateTime.now().difference(refDate).inDays ~/ 7;

    return (initialAge + weeksPassed).clamp(0, 42);
  }

  DateTime? calculateDueDate(Map<String, dynamic> data) {
    final Timestamp? lmpTs = data['pregnancy']?['lmpEstimated'];
    if (lmpTs == null) return null;
    return lmpTs.toDate().add(const Duration(days: 280));
  }

  int calculateDaysRemaining(DateTime? dueDate) {
    if (dueDate == null) return 0;
    final today = DateTime.now();
    return dueDate.difference(today).inDays.clamp(0, 280);
  }

  String getCurrentTrimester(int gestationalAge) {
    if (gestationalAge < 12) return "First Trimester";
    if (gestationalAge < 28) return "Second Trimester";
    return "Third Trimester";
  }

  String getBabySize(int gestationalAge) {
    final sizes = {
      4: "Poppy seed", 6: "Lentil", 8: "Raspberry", 10: "Strawberry",
      12: "Lime", 16: "Avocado", 20: "Banana", 24: "Corn",
      28: "Eggplant", 32: "Pineapple", 36: "Papaya", 40: "Watermelon"
    };

    for (var week in sizes.keys.toList().reversed) {
      if (gestationalAge >= week) return sizes[week]!;
    }
    return "Tiny seed";
  }

  String getCurrentDevelopment(int gestationalAge) {
    if (gestationalAge < 12) {
      return 'Your baby\'s major organs are forming. The heart begins to beat and limbs start developing.';
    } else if (gestationalAge < 20) {
      return 'Baby is growing rapidly! You may start feeling those first gentle kicks and movements.';
    } else if (gestationalAge < 28) {
      return 'Baby\'s senses are developing beautifully. They can now hear your voice and respond to sounds.';
    } else if (gestationalAge < 37) {
      return 'Baby is gaining weight steadily and practicing important skills like breathing and swallowing.';
    } else {
      return 'Your little one is fully developed and ready to meet you! Stay prepared for their arrival.';
    }
  }

  List<Map<String, dynamic>> getMilestones(int gestationalAge) {
    final allMilestones = [
      {'week': 4, 'title': 'Neural tube forms', 'icon': Icons.psychology},
      {'week': 8, 'title': 'Heart beats regularly', 'icon': Icons.favorite},
      {'week': 12, 'title': 'First trimester complete!', 'icon': Icons.celebration},
      {'week': 16, 'title': 'Gender can be determined', 'icon': Icons.child_care},
      {'week': 20, 'title': 'Halfway milestone!', 'icon': Icons.emoji_emotions},
      {'week': 24, 'title': 'Viable outside womb', 'icon': Icons.shield},
      {'week': 28, 'title': 'Third trimester begins', 'icon': Icons.timeline},
      {'week': 32, 'title': 'Bones hardening', 'icon': Icons.fitness_center},
      {'week': 36, 'title': 'Lungs nearly mature', 'icon': Icons.air},
      {'week': 37, 'title': 'Full-term reached!', 'icon': Icons.star},
    ];

    return allMilestones.where((m) => gestationalAge >= (m['week'] as int)).toList();
  }

  /// ---- UI BUILDERS ----
  Widget _buildHeroSection(int gestationalAge, DateTime? dueDate) {
    final progress = (gestationalAge / 40.0).clamp(0.0, 1.0);
    final daysRemaining = calculateDaysRemaining(dueDate);
    final trimester = getCurrentTrimester(gestationalAge);
    final babySize = getBabySize(gestationalAge);

    _progressController.animateTo(progress);

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.pink.shade300,
            Colors.pink.shade500,
            Colors.purple.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$gestationalAge weeks',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      trimester,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.child_care,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        babySize,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Progress Bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimation.value * progress,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        borderRadius: BorderRadius.circular(4),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Due Date Info
            if (dueDate != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Due Date',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$daysRemaining days',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevelopmentCard(String development) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade400, Colors.purple.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.baby_changing_station,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Baby\'s Development',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            development,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF4A5568),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection(int gestationalAge) {
    final milestones = getMilestones(gestationalAge);

    if (milestones.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.teal.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Milestones Achieved',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...milestones.take(4).map((milestone) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade500,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    milestone['icon'],
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        'Week ${milestone['week']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade500,
                  size: 24,
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildQuickStats(int gestationalAge, DateTime? dueDate) {
    final daysRemaining = calculateDaysRemaining(dueDate);
    final trimester = getCurrentTrimester(gestationalAge);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Trimester',
              trimester,
              Icons.timeline,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Days Left',
              '$daysRemaining',
              Icons.access_time,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// ---- MAIN BUILD ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder<DocumentSnapshot>(
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
          final currentDevelopment = getCurrentDevelopment(gestationalAge);
          final dueDate = calculateDueDate(data);

          return FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 100,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  floating: true,
                  flexibleSpace: const FlexibleSpaceBar(
                    title: Text(
                      'Pregnancy Tracker',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      if (gestationalAge > 0) ...[
                        _buildHeroSection(gestationalAge, dueDate),
                        _buildQuickStats(gestationalAge, dueDate),
                        const SizedBox(height: 10),
                      ],
                      _buildDevelopmentCard(currentDevelopment),
                      _buildMilestonesSection(gestationalAge),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}