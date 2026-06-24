import 'package:bebezen/core/services/account_service.dart';
import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/features/partner/partner_calendar.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
// ROUTING WIDGET
// ─────────────────────────────────────────────
class PartnerMode extends StatelessWidget {
  const PartnerMode({super.key});

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
        return snapshot.data!.data()?['role'] == 'partner'
            ? const PartnerDashboard()
            : const PartnerConnectionPage();
      },
    );
  }
}

// ─────────────────────────────────────────────
// CONNECTION PAGE (invite partner — mother side)
// ─────────────────────────────────────────────
class PartnerConnectionPage extends StatefulWidget {
  const PartnerConnectionPage({super.key});

  @override
  State<PartnerConnectionPage> createState() => _PartnerConnectionPageState();
}

class _PartnerConnectionPageState extends State<PartnerConnectionPage> {
  bool _loading = false;
  String? _code;

  Future<void> _createInvite() async {
    setState(() => _loading = true);
    try {
      final code = await AccountService().createPartnerInvite();
      if (mounted) setState(() => _code = code);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to create invitation: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Partner access')),
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
            builder: (context, householdSnapshot) {
              if (!householdSnapshot.hasData) return const BZLoading();
              final partnerId =
                  householdSnapshot.data!.data()?['partnerId'] as String?;
              final partnerLinked = partnerId != null;
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(
                    Icons.family_restroom,
                    size: 64,
                    color: BebezenPalette.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    partnerLinked
                        ? 'Your partner is connected'
                        : 'Invite the baby\'s father',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (partnerId != null) ...[
                    const SizedBox(height: 8),
                    _MemberName(userId: partnerId, prefix: 'Connected with'),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    partnerLinked
                        ? 'You can now share tasks, pregnancy progress and messages.'
                        : 'He will use this code when creating his own partner account. The code expires after 7 days.',
                    textAlign: TextAlign.center,
                  ),
                  if (partnerLinked) ...[
                    const SizedBox(height: 20),
                    BZButton(
                      label: 'Manage shared tasks',
                      icon: Icons.checklist_rounded,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PartnerTasksPage(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (_code != null)
                    BZCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _code!,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy code',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _code!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invitation code copied.'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                          ),
                        ],
                      ),
                    ),
                  if (!partnerLinked) ...[
                    const SizedBox(height: 20),
                    BZButton(
                      label: _code == null
                          ? 'Create invitation code'
                          : 'Generate a new code',
                      icon: Icons.person_add_alt_1,
                      isLoading: _loading,
                      onPressed: _createInvite,
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PARTNER DASHBOARD — centre de suivi (lecture)
// ─────────────────────────────────────────────
class PartnerDashboard extends StatelessWidget {
  const PartnerDashboard({super.key});

  static int _currentWeek(Map<String, dynamic> pregnancy) {
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
      backgroundColor: BebezenPalette.partnerBackground,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: BZLoading());
          final user = userSnapshot.data!.data() ?? {};
          final householdId = user['householdId'] as String?;
          if (householdId == null) return const Center(child: BZLoading());

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('households')
                .doc(householdId)
                .snapshots(),
            builder: (context, householdSnapshot) {
              if (!householdSnapshot.hasData) {
                return const Center(child: BZLoading());
              }
              final household = householdSnapshot.data!.data() ?? {};
              final pregnancy = Map<String, dynamic>.from(
                household['pregnancy'] as Map? ?? {},
              );
              final week = _currentWeek(pregnancy);
              final dueDate = (pregnancy['dueDate'] as Timestamp?)?.toDate();
              final motherId = household['motherId'] as String?;
              final userName = user['name'] as String? ?? 'Partner';

              final hour = DateTime.now().hour;
              final greeting = hour < 12
                  ? 'Good morning'
                  : hour < 18
                  ? 'Good afternoon'
                  : 'Good evening';

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: BebezenPalette.partnerBackground,
                    elevation: 0,
                    title: const Text(
                      'Family Dashboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BebezenPalette.textPrimary,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Active SOS Banner ──
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('households')
                              .doc(householdId)
                              .collection('sosAlerts')
                              .where('status', isEqualTo: 'active')
                              .limit(1)
                              .snapshots(),
                          builder: (context, sosSnap) {
                            final docs = sosSnap.data?.docs ?? [];
                            if (docs.isEmpty) return const SizedBox.shrink();
                            final reason =
                                docs.first.data()['reason'] as String? ??
                                'Emergency';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.emergency,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '🚨 EMERGENCY ALERT',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          reason,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // ── Greeting ──
                        Text(
                          '$greeting, $userName 👋',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: BebezenPalette.textPrimary,
                          ),
                        ),
                        if (motherId != null)
                          _MemberName(userId: motherId, prefix: 'Supporting'),
                        const SizedBox(height: 20),

                        // ── Card 1: Pregnancy Progress ──
                        _PregnancyProgressCard(week: week, dueDate: dueDate),
                        const SizedBox(height: 16),

                        // ── Card 2: Shared Calendar ──
                        _SharedCalendarCard(householdId: householdId),
                        const SizedBox(height: 16),

                        // ── Card 3: Emergency Status ──
                        _SosStatusCard(householdId: householdId),
                        const SizedBox(height: 16),

                        // ── Card 4: Support Tasks (partagées) ──
                        _SupportTasksCard(householdId: householdId),
                        const SizedBox(height: 16),

                        // ── Card 5: Weekly Learning ──
                        _WeeklyLearningCard(week: week),
                      ]),
                    ),
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

// ─────────────────────────────────────────────
// CARD 1 : PREGNANCY PROGRESS
// ─────────────────────────────────────────────
class _PregnancyProgressCard extends StatelessWidget {
  const _PregnancyProgressCard({required this.week, this.dueDate});
  final int week;
  final DateTime? dueDate;

  static String _babyEmoji(int w) {
    if (w <= 5) return '🌱';
    if (w <= 7) return '🫛';
    if (w <= 9) return '🫐';
    if (w <= 11) return '🍓';
    if (w <= 13) return '🍋';
    if (w <= 15) return '🥑';
    if (w <= 17) return '🍠';
    if (w <= 21) return '🍌';
    if (w <= 25) return '🌽';
    if (w <= 29) return '🍆';
    if (w <= 33) return '🍍';
    if (w <= 37) return '🎃';
    return '🍉';
  }

  static String _babySize(int w) {
    if (w <= 5) return 'Poppy seed';
    if (w <= 7) return 'Lentil';
    if (w <= 9) return 'Raspberry';
    if (w <= 11) return 'Strawberry';
    if (w <= 13) return 'Lime';
    if (w <= 15) return 'Avocado';
    if (w <= 17) return 'Sweet potato';
    if (w <= 21) return 'Banana';
    if (w <= 25) return 'Corn';
    if (w <= 29) return 'Eggplant';
    if (w <= 33) return 'Pineapple';
    if (w <= 37) return 'Butternut squash';
    return 'Watermelon';
  }

  static String _trimester(int w) {
    if (w < 13) return 'First Trimester';
    if (w < 28) return 'Second Trimester';
    return 'Third Trimester';
  }

  @override
  Widget build(BuildContext context) {
    final progress = (week / 40.0).clamp(0.0, 1.0);
    final daysLeft = dueDate != null
        ? dueDate!.difference(DateTime.now()).inDays.clamp(0, 280)
        : (40 - week) * 7;

    return Container(
      decoration: BoxDecoration(
        gradient: BebezenPalette.partnerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: BebezenPalette.partnerPrimary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week $week of 40',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _trimester(week),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      _babyEmoji(week),
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _babySize(week),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progression',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white70, size: 15),
              const SizedBox(width: 5),
              Text(
                '$daysLeft days until estimated due date',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CARD 2 : SHARED CALENDAR (read-only preview)
// ─────────────────────────────────────────────
class _SharedCalendarCard extends StatelessWidget {
  const _SharedCalendarCard({required this.householdId});
  final String householdId;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .collection('events')
          .where('dateTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('dateTime')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return BZCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: BebezenPalette.partnerPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Shared Calendar',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PartnerCalendarPage(),
                      ),
                    ),
                    child: const Text('View all →'),
                  ),
                ],
              ),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No upcoming events',
                    style: TextStyle(
                      color: BebezenPalette.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ...docs.map((doc) {
                  final data = doc.data();
                  final title = data['title'] as String? ?? '';
                  final dt = (data['dateTime'] as Timestamp).toDate();
                  final type = data['type'] as String? ?? 'Other';
                  final attending = data['partnerAttending'] as bool?;
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: BebezenPalette.partnerPrimaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('d').format(dt),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: BebezenPalette.partnerPrimary,
                                ),
                              ),
                              Text(
                                DateFormat('MMM').format(dt),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: BebezenPalette.partnerPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${DateFormat('HH:mm').format(dt)}  •  $type',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: BebezenPalette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (attending == true)
                          const Icon(
                            Icons.check_circle,
                            color: BebezenPalette.success,
                            size: 18,
                          )
                        else if (attending == false)
                          const Icon(
                            Icons.cancel_outlined,
                            color: BebezenPalette.error,
                            size: 18,
                          )
                        else
                          const Icon(
                            Icons.help_outline,
                            color: BebezenPalette.textSecondary,
                            size: 18,
                          ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// CARD 5 : SUPPORT TASKS (partagées)
// Correction : pas de where+orderBy (évite l'index composite)
// Filtre "completed = false" en mémoire
// ─────────────────────────────────────────────
class _SupportTasksCard extends StatelessWidget {
  const _SupportTasksCard({required this.householdId});
  final String householdId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        // Filter pending tasks in memory — avoids composite index requirement
        final allDocs = snapshot.data?.docs ?? [];
        final pendingDocs = allDocs
            .where((d) => d.data()['completed'] != true)
            .take(3)
            .toList();
        final totalPending = allDocs
            .where((d) => d.data()['completed'] != true)
            .length;

        return BZCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.task_alt,
                    color: BebezenPalette.partnerPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Shared Tasks',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PartnerTasksPage(),
                      ),
                    ),
                    child: Text(
                      totalPending > 3
                          ? 'View all ($totalPending) →'
                          : 'View all →',
                    ),
                  ),
                ],
              ),
              if (allDocs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No tasks yet. The mother adds shared tasks.',
                    style: TextStyle(
                      color: BebezenPalette.textSecondary,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                )
              else if (pendingDocs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: const [
                      Text('🎉', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text(
                        'All tasks completed!',
                        style: TextStyle(
                          color: BebezenPalette.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...pendingDocs.map((doc) {
                  final data = doc.data();
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: false,
                    title: Text(
                      data['title'] as String? ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    onChanged: (_) => doc.reference.update({
                      'completed': true,
                      'completedBy': FirebaseAuth.instance.currentUser?.uid,
                      'completedAt': FieldValue.serverTimestamp(),
                    }),
                    activeColor: BebezenPalette.partnerPrimary,
                    dense: true,
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// CARD 3 : EMERGENCY STATUS (SOS de la mère)
// SAFE par défaut — ALERTE si SOS déclenché
// ─────────────────────────────────────────────
class _SosStatusCard extends StatelessWidget {
  const _SosStatusCard({required this.householdId});
  final String householdId;

  Future<void> _markResolved(String alertId) async {
    await FirebaseFirestore.instance
        .collection('households')
        .doc(householdId)
        .collection('sosAlerts')
        .doc(alertId)
        .update({
          'status': 'resolved',
          'resolvedAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .collection('sosAlerts')
          .where('status', isEqualTo: 'active')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final hasAlert = docs.isNotEmpty;

        if (!hasAlert) {
          return BZCard(
            color: const Color(0xFFE8F5E9),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BebezenPalette.success.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: BebezenPalette.success,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Status',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'SAFE  ✅',
                      style: TextStyle(
                        color: BebezenPalette.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final alert = docs.first;
        final data = alert.data();
        final reason = data['reason'] as String? ?? 'Emergency';
        final triggeredAt = (data['triggeredAt'] as Timestamp?)?.toDate();
        final timeStr = triggeredAt != null
            ? DateFormat('HH:mm').format(triggeredAt)
            : '';

        return BZCard(
          color: const Color(0xFFFFEBEE),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emergency,
                    color: BebezenPalette.error,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '🚨 ACTIVE EMERGENCY',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: BebezenPalette.error,
                    ),
                  ),
                  const Spacer(),
                  if (timeStr.isNotEmpty)
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: BebezenPalette.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                reason,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BebezenPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _markResolved(alert.id),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Mark as resolved'),
                  style: FilledButton.styleFrom(
                    backgroundColor: BebezenPalette.success,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// CARD 7 : WEEKLY LEARNING
// ─────────────────────────────────────────────
class _WeeklyLearningCard extends StatelessWidget {
  const _WeeklyLearningCard({required this.week});
  final int week;

  static ({
    String babyDevelopment,
    List<String> motherSymptoms,
    List<String> partnerTips,
  })
  _content(int w) {
    if (w <= 6) {
      return (
        babyDevelopment:
            'The embryo is forming rapidly. The neural tube, heart and major organs are starting to develop.',
        motherSymptoms: [
          'Fatigue',
          'Nausea',
          'Tender breasts',
          'Mild cramping',
        ],
        partnerTips: [
          'Be patient with mood changes',
          'Help prepare light meals',
          'Avoid cooking strong-smelling foods',
          'Book the first prenatal visit together',
        ],
      );
    }
    if (w <= 12) {
      return (
        babyDevelopment:
            'All major organs are forming. Baby\'s heart beats at 160 bpm. Fingers and toes are developing.',
        motherSymptoms: [
          'Morning sickness',
          'Fatigue',
          'Frequent urination',
          'Mood swings',
        ],
        partnerTips: [
          'Attend the first ultrasound',
          'Take over household tasks',
          'Keep crackers available for nausea',
          'Offer reassurance and patience',
        ],
      );
    }
    if (w <= 18) {
      return (
        babyDevelopment:
            'Baby is growing rapidly and can now make facial expressions. The gender may be visible on ultrasound.',
        motherSymptoms: [
          'Increased appetite',
          'Mild back pain',
          'Skin changes',
          'Nasal congestion',
        ],
        partnerTips: [
          'Attend the anatomy scan together',
          'Offer back massages',
          'Prepare nutritious snacks',
          'Start planning the nursery',
        ],
      );
    }
    if (w <= 24) {
      return (
        babyDevelopment:
            'Baby can now hear voices and respond to sounds. This is a great time to talk and read to your baby.',
        motherSymptoms: [
          'Back pain',
          'Swollen feet',
          'Heartburn',
          'Fatigue returning',
        ],
        partnerTips: [
          'Talk and sing to the baby',
          'Help with foot massages',
          'Prepare heartburn-friendly meals',
          'Research childbirth options together',
        ],
      );
    }
    if (w <= 30) {
      return (
        babyDevelopment:
            'Baby\'s brain is developing rapidly. Kicks are stronger and baby is practicing breathing movements.',
        motherSymptoms: [
          'Shortness of breath',
          'Braxton Hicks contractions',
          'Frequent urination',
          'Insomnia',
        ],
        partnerTips: [
          'Feel the baby kick together',
          'Set up the nursery',
          'Start packing the hospital bag',
          'Take a childbirth preparation class',
        ],
      );
    }
    if (w <= 36) {
      return (
        babyDevelopment:
            'Baby is gaining weight fast and preparing for birth. Lungs are maturing. Baby may move into head-down position.',
        motherSymptoms: [
          'Pelvic pressure',
          'Intense back pain',
          'Difficulty sleeping',
          'Swelling in legs',
        ],
        partnerTips: [
          'Finalize the hospital transport plan',
          'Learn labor support techniques',
          'Keep phone charged and nearby',
          'Confirm the hospital bag is ready',
        ],
      );
    }
    return (
      babyDevelopment:
          'Baby is fully developed and ready to meet you! Stay alert for signs of labor and keep all emergency contacts ready.',
      motherSymptoms: [
        'Increased contractions',
        'Nesting instinct',
        'Pelvic pressure',
        'Anxiety about delivery',
      ],
      partnerTips: [
        'Be available at all times',
        'Know the route to the hospital',
        'Practice breathing exercises together',
        'Stay calm — your presence matters most',
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _content(week);
    return BZCard(
      color: const Color(0xFFF3E5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book,
                color: BebezenPalette.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Week $week — Learning',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: BebezenPalette.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LSection(
            icon: '👶',
            title: 'Baby\'s Development',
            body: c.babyDevelopment,
          ),
          const SizedBox(height: 12),
          _LList(
            icon: '🤱',
            title: 'Mother may experience',
            items: c.motherSymptoms,
          ),
          const SizedBox(height: 12),
          _LList(icon: '✅', title: 'How you can help', items: c.partnerTips),
        ],
      ),
    );
  }
}

class _LSection extends StatelessWidget {
  const _LSection({
    required this.icon,
    required this.title,
    required this.body,
  });
  final String icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$icon $title',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: BebezenPalette.secondary,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        body,
        style: const TextStyle(
          fontSize: 13,
          color: BebezenPalette.textSecondary,
          height: 1.5,
        ),
      ),
    ],
  );
}

class _LList extends StatelessWidget {
  const _LList({required this.icon, required this.title, required this.items});
  final String icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$icon $title',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: BebezenPalette.secondary,
        ),
      ),
      const SizedBox(height: 5),
      ...items.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '•  ',
                style: TextStyle(
                  fontSize: 13,
                  color: BebezenPalette.textSecondary,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 13,
                    color: BebezenPalette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────
// PARTNER TASKS PAGE (tâches partagées)
// ─────────────────────────────────────────────
class PartnerTasksPage extends StatefulWidget {
  const PartnerTasksPage({super.key});

  @override
  State<PartnerTasksPage> createState() => _PartnerTasksPageState();
}

class _PartnerTasksPageState extends State<PartnerTasksPage> {
  late final Future<_TaskAccess?> _accessFuture;

  @override
  void initState() {
    super.initState();
    _accessFuture = _taskAccess();
  }

  Future<_TaskAccess?> _taskAccess() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = user.data();
    final householdId = data?['householdId'] as String?;
    if (householdId == null) return null;
    return _TaskAccess(
      householdId: householdId,
      role: data?['role'] as String? ?? 'mother',
    );
  }

  Future<void> _addTask() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New shared task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Task title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;
    final access = await _accessFuture;
    if (access == null || !access.canCreateTasks) return;
    try {
      await FirebaseFirestore.instance
          .collection('households')
          .doc(access.householdId)
          .collection('tasks')
          .add({
            'title': title,
            'completed': false,
            'createdBy': FirebaseAuth.instance.currentUser!.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Unable to add task.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Tasks'),
        backgroundColor: BebezenPalette.partnerBackground,
        foregroundColor: BebezenPalette.partnerPrimary,
        elevation: 0,
      ),
      backgroundColor: BebezenPalette.partnerBackground,
      body: FutureBuilder<_TaskAccess?>(
        future: _accessFuture,
        builder: (context, accessSnapshot) {
          if (accessSnapshot.hasError) {
            return Center(child: Text('Error: ${accessSnapshot.error}'));
          }
          final access = accessSnapshot.data;
          if (access == null) return const BZLoading();
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('households')
                .doc(access.householdId)
                .collection('tasks')
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) return const BZLoading();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    access.canCreateTasks
                        ? 'No shared tasks yet. Add the first one.'
                        : 'No shared tasks yet. The mother adds tasks here.',
                  ),
                );
              }
              // Separate pending from completed for visual grouping
              final pending = docs
                  .where((d) => d.data()['completed'] != true)
                  .toList();
              final done = docs
                  .where((d) => d.data()['completed'] == true)
                  .toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  if (pending.isNotEmpty) ...[
                    const _SectionHeader(title: 'To do'),
                    const SizedBox(height: 8),
                    ...pending.map(
                      (doc) => _TaskTile(doc: doc, access: access),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (done.isNotEmpty) ...[
                    const _SectionHeader(title: 'Completed'),
                    const SizedBox(height: 8),
                    ...done.map((doc) => _TaskTile(doc: doc, access: access)),
                  ],
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<_TaskAccess?>(
        future: _accessFuture,
        builder: (context, snapshot) {
          final access = snapshot.data;
          if (access == null || !access.canCreateTasks) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: _addTask,
            backgroundColor: BebezenPalette.partnerPrimary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

class _TaskAccess {
  const _TaskAccess({required this.householdId, required this.role});

  final String householdId;
  final String role;

  bool get canCreateTasks => role == 'mother';
  bool get canDeleteTasks => role == 'mother';
  bool get canToggleStatus => role == 'partner';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: BebezenPalette.textSecondary,
      letterSpacing: 0.5,
    ),
  );
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.doc, required this.access});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final _TaskAccess access;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final completed = data['completed'] == true;
    final completedAt = data['completedAt'] as Timestamp?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BZCard(
        padding: EdgeInsets.zero,
        child: CheckboxListTile(
          value: completed,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['title'] as String? ?? '',
                style: TextStyle(
                  decoration: completed ? TextDecoration.lineThrough : null,
                  color: completed ? BebezenPalette.textSecondary : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                completed
                    ? 'Fait${completedAt == null ? '' : ' • ${DateFormat('dd/MM HH:mm').format(completedAt.toDate())}'}'
                    : 'À faire',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: completed
                      ? BebezenPalette.success
                      : BebezenPalette.textSecondary,
                ),
              ),
            ],
          ),
          secondary: access.canDeleteTasks
              ? IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: doc.reference.delete,
                )
              : null,
          onChanged: access.canToggleStatus
              ? (val) => doc.reference.update({
                  'completed': val == true,
                  'completedBy': val == true
                      ? FirebaseAuth.instance.currentUser?.uid
                      : null,
                  'completedAt': val == true
                      ? FieldValue.serverTimestamp()
                      : null,
                })
              : null,
          subtitle: !access.canToggleStatus
              ? const Text('Le partenaire marque la tâche faite ou non faite.')
              : null,
          activeColor: BebezenPalette.partnerPrimary,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────
class _MemberName extends StatelessWidget {
  const _MemberName({required this.userId, required this.prefix});
  final String userId;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final name = snapshot.data?.data()?['name'] as String?;
        if (name == null) return const SizedBox.shrink();
        return Text(
          '$prefix $name',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        );
      },
    );
  }
}
