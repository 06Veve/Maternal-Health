import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/features/health/kick_counter.dart';
import 'package:bebezen/features/health/reminders.dart';
import 'package:bebezen/features/health/symptom_tracker.dart';
import 'package:bebezen/features/health/wellness_tracker.dart';
import 'package:bebezen/features/partner/partner_mode.dart';
import 'package:bebezen/home_nav_pages/preg_tracker.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Insights extends StatelessWidget {
  const Insights({super.key});

  int _week(Map<String, dynamic> pregnancy) {
    final initial = pregnancy['gestationalAgeWeeks'] as int? ?? 0;
    final reference = pregnancy['referenceDate'] as Timestamp?;
    if (reference == null) return initial;
    return (initial + DateTime.now().difference(reference.toDate()).inDays ~/ 7)
        .clamp(0, 42);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insights'),
            Text(
              'Your pregnancy at a glance',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          final householdId =
              userSnapshot.data?.data()?['householdId'] as String?;
          if (householdId == null) return const BZLoading();
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('households')
                .doc(householdId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const BZLoading();
              final household = snapshot.data!.data() ?? {};
              final pregnancy = Map<String, dynamic>.from(
                household['pregnancy'] as Map? ?? {},
              );
              final week = _week(pregnancy);
              final dueDate = pregnancy['dueDate'] as Timestamp?;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                children: [
                  _ProgressHeader(week: week, dueDate: dueDate?.toDate()),
                  const SizedBox(height: 24),
                  Text(
                    'Track your health',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: .95,
                    children: [
                      _InsightTile(
                        icon: Icons.timeline,
                        title: 'Pregnancy',
                        subtitle: 'Progress & milestones',
                        color: const Color(0xFF7357D6),
                        onTap: () => _open(context, PregnancyTrackerPage()),
                      ),
                      _InsightTile(
                        icon: Icons.monitor_heart_outlined,
                        title: 'Symptoms',
                        subtitle: 'Daily check-ins & PDF',
                        color: const Color(0xFFE05276),
                        onTap: () => _open(context, const SymptomTracker()),
                      ),
                      _InsightTile(
                        icon: Icons.favorite_outline,
                        title: 'Baby kicks',
                        subtitle: 'Movement sessions',
                        color: const Color(0xFFE66B6B),
                        onTap: () => _open(context, const KickCounter()),
                      ),
                      _InsightTile(
                        icon: Icons.restaurant_menu,
                        title: 'Wellness',
                        subtitle: 'Water, meals & activity',
                        color: const Color(0xFF399B76),
                        onTap: () =>
                            _open(context, const WellnessTrackerPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Plan & support',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _WideAction(
                    icon: Icons.notifications_active_outlined,
                    title: 'Reminders',
                    subtitle: 'Vitamins and appointments',
                    onTap: () => _open(context, const RemindersPage()),
                  ),
                  _WideAction(
                    icon: Icons.family_restroom,
                    title: 'Partner access',
                    subtitle: household['partnerId'] == null
                        ? 'Invite the baby’s father'
                        : 'Your partner is connected',
                    onTap: () => _open(context, const PartnerMode()),
                  ),
                  _WideAction(
                    icon: Icons.lightbulb_outline,
                    title: 'Tips for week $week',
                    subtitle: 'Practical recommendations for this stage',
                    onTap: () => _open(context, PregnancyTipsPage(week: week)),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static void _open(BuildContext context, Widget page) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.week, required this.dueDate});
  final int week;
  final DateTime? dueDate;

  @override
  Widget build(BuildContext context) {
    final progress = (week / 40).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: BebezenPalette.primaryGradient,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Week $week',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.pregnant_woman, color: Colors.white, size: 38),
            ],
          ),
          Text(
            dueDate == null
                ? 'Estimated due date unavailable'
                : 'Estimated due ${DateFormat('d MMMM yyyy').format(dueDate!)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${(40 - week).clamp(0, 40)} weeks remaining',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BZCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WideAction extends StatelessWidget {
  const _WideAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BZCard(
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: BebezenPalette.primaryLight,
              child: Icon(icon, color: BebezenPalette.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class PregnancyTipsPage extends StatelessWidget {
  const PregnancyTipsPage({super.key, required this.week});
  final int week;

  List<(IconData, String, String)> get _tips {
    if (week <= 13) {
      return [
        (
          Icons.local_drink,
          'Hydration',
          'Sip water regularly, especially if nausea makes larger drinks difficult.',
        ),
        (
          Icons.medication_outlined,
          'Prenatal vitamins',
          'Take supplements only as recommended by your maternity professional.',
        ),
        (
          Icons.bedtime_outlined,
          'Rest',
          'Fatigue is common in the first trimester. Build short rest periods into your day.',
        ),
      ];
    }
    if (week <= 27) {
      return [
        (
          Icons.directions_walk,
          'Gentle movement',
          'If your clinician agrees, regular moderate movement can support wellbeing.',
        ),
        (
          Icons.restaurant,
          'Balanced meals',
          'Include protein, vegetables and iron-rich foods across the day.',
        ),
        (
          Icons.calendar_month,
          'Appointments',
          'Keep prenatal visits and note questions before each appointment.',
        ),
      ];
    }
    return [
      (
        Icons.local_hospital_outlined,
        'Birth preparation',
        'Review your birth plan and transport arrangements with your care team.',
      ),
      (
        Icons.favorite_outline,
        'Baby movements',
        'Learn your baby’s usual movement pattern and contact care urgently if it changes.',
      ),
      (
        Icons.work_outline,
        'Hospital bag',
        'Prepare essential documents and supplies before the final weeks.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tips for week $week')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ..._tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BZCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: BebezenPalette.primaryLight,
                      child: Icon(tip.$1, color: BebezenPalette.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip.$2,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(tip.$3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const BZCard(
            child: Text(
              'This information is educational and does not replace advice from your doctor or midwife. Seek urgent care for severe or worrying symptoms.',
            ),
          ),
        ],
      ),
    );
  }
}
