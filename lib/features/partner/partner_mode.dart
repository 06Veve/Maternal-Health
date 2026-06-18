import 'package:bebezen/core/services/account_service.dart';
import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                        : 'Invite the baby’s father',
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

class PartnerDashboard extends StatelessWidget {
  const PartnerDashboard({super.key});

  int _currentWeek(Map<String, dynamic> pregnancy) {
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
      appBar: AppBar(title: const Text('Family overview')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          final user = userSnapshot.data?.data();
          final householdId = user?['householdId'] as String?;
          if (householdId == null) return const BZLoading();
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('households')
                .doc(householdId)
                .snapshots(),
            builder: (context, householdSnapshot) {
              if (!householdSnapshot.hasData) return const BZLoading();
              final household = householdSnapshot.data!.data() ?? {};
              final pregnancy = Map<String, dynamic>.from(
                household['pregnancy'] as Map? ?? {},
              );
              final week = _currentWeek(pregnancy);
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Hello ${user?['name'] ?? 'Partner'}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (household['motherId'] case final String motherId)
                    _MemberName(userId: motherId, prefix: 'Supporting'),
                  const Text('Here is how you can support your family today.'),
                  const SizedBox(height: 24),
                  BZCard(
                    color: BebezenPalette.primaryLight,
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.pregnant_woman,
                            color: BebezenPalette.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pregnancy week $week',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                '${(40 - week).clamp(0, 40)} weeks until the estimated due date',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Today’s support',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const _SupportTip(
                    icon: Icons.restaurant,
                    title: 'Prepare a balanced meal',
                    detail: 'Prioritize iron, protein and hydration.',
                  ),
                  const _SupportTip(
                    icon: Icons.spa,
                    title: 'Create time to rest',
                    detail: 'Take over one task and encourage a short break.',
                  ),
                  const _SupportTip(
                    icon: Icons.chat_bubble_outline,
                    title: 'Check in emotionally',
                    detail: 'Ask how she feels and listen without rushing.',
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

class PartnerTasksPage extends StatefulWidget {
  const PartnerTasksPage({super.key});

  @override
  State<PartnerTasksPage> createState() => _PartnerTasksPageState();
}

class _PartnerTasksPageState extends State<PartnerTasksPage> {
  late final Future<String?> _householdFuture;

  @override
  void initState() {
    super.initState();
    _householdFuture = _householdId();
  }

  Future<String?> _householdId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return user.data()?['householdId'] as String?;
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
    final householdId = await _householdId();
    if (householdId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
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
      appBar: AppBar(title: const Text('Shared tasks')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<String?>(
        future: _householdFuture,
        builder: (context, householdSnapshot) {
          if (householdSnapshot.hasError) {
            return Center(
              child: Text('Unable to load tasks: ${householdSnapshot.error}'),
            );
          }
          final householdId = householdSnapshot.data;
          if (householdId == null) return const BZLoading();
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('households')
                .doc(householdId)
                .collection('tasks')
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Unable to load tasks: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) return const BZLoading();
              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No shared tasks yet.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BZCard(
                      padding: EdgeInsets.zero,
                      child: CheckboxListTile(
                        value: data['completed'] == true,
                        title: Text(data['title'] ?? ''),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: doc.reference.delete,
                        ),
                        onChanged: (value) => doc.reference.update({
                          'completed': value == true,
                          'completedBy': value == true
                              ? FirebaseAuth.instance.currentUser!.uid
                              : null,
                          'completedAt': value == true
                              ? FieldValue.serverTimestamp()
                              : null,
                        }),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

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

class _SupportTip extends StatelessWidget {
  const _SupportTip({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BZCard(
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
                  Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
