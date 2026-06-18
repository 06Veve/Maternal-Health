import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CoupleChatPage extends StatefulWidget {
  const CoupleChatPage({super.key, this.active = true});

  final bool active;

  @override
  State<CoupleChatPage> createState() => _CoupleChatPageState();
}

class _CoupleChatPageState extends State<CoupleChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String? _householdId;
  String? _lastMarkedMessageId;
  final Map<String, String> _memberNames = {};

  @override
  void initState() {
    super.initState();
    _loadHousehold();
  }

  @override
  void didUpdateWidget(covariant CoupleChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _markAsRead();
    }
  }

  Future<void> _loadHousehold() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final userData = user.data();
    final ownName = userData?['name'] as String?;
    if (ownName != null && ownName.trim().isNotEmpty) {
      _memberNames[uid] = ownName.trim();
    }
    final householdId = userData?['householdId'] as String?;
    if (householdId != null) {
      final household = await FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .get();
      final memberIds = <String>{
        if (household.data()?['motherId'] case final String id) id,
        if (household.data()?['partnerId'] case final String id) id,
      };
      for (final memberId in memberIds.where((id) => id != uid)) {
        final member = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .get();
        final name = member.data()?['name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          _memberNames[memberId] = name.trim();
        }
      }
    }
    if (mounted) {
      setState(() => _householdId = householdId);
    }
    if (widget.active) {
      await _markAsRead();
    }
  }

  Future<void> _markAsRead() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chatState')
        .doc('family')
        .set({
          'lastReadAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final householdId = _householdId;
    if (text.isEmpty || householdId == null) {
      return;
    }
    _controller.clear();
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance
        .collection('households')
        .doc(householdId)
        .collection('messages')
        .add({
          'text': text,
          'senderId': user.uid,
          'senderName':
              _memberNames[user.uid] ??
              user.displayName ??
              user.email?.split('@').first ??
              'Family',
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'text',
        });
    await _markAsRead();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final householdId = _householdId;
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Family chat'),
            Text(
              'Private conversation',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: householdId == null
          ? const BZLoading()
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('households')
                        .doc(householdId)
                        .collection('messages')
                        .orderBy('createdAt', descending: true)
                        .limit(100)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const BZLoading();
                      if (snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Start your private family conversation.',
                          ),
                        );
                      }
                      final latest = snapshot.data!.docs.first;
                      if (widget.active &&
                          latest.data()['senderId'] != currentUid &&
                          latest.id != _lastMarkedMessageId) {
                        _lastMarkedMessageId = latest.id;
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _markAsRead(),
                        );
                      }
                      return ListView.builder(
                        reverse: true,
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final data = snapshot.data!.docs[index].data();
                          final mine = data['senderId'] == currentUid;
                          final timestamp = data['createdAt'] as Timestamp?;
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * .78,
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: mine
                                    ? BebezenPalette.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(mine ? 20 : 4),
                                  bottomRight: Radius.circular(mine ? 4 : 20),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _memberNames[data['senderId']] ??
                                        data['senderName'] ??
                                        'Partner',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: mine
                                          ? Colors.white70
                                          : BebezenPalette.primary,
                                    ),
                                  ),
                                  Text(
                                    data['text'] ?? '',
                                    style: TextStyle(
                                      color: mine
                                          ? Colors.white
                                          : BebezenPalette.textPrimary,
                                    ),
                                  ),
                                  if (timestamp != null)
                                    Text(
                                      DateFormat(
                                        'HH:mm',
                                      ).format(timestamp.toDate()),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: mine
                                            ? Colors.white70
                                            : BebezenPalette.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: BebezenPalette.divider),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 4,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(
                              hintText: 'Write a message…',
                              filled: false,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: _send,
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class FamilyChatBadge extends StatelessWidget {
  const FamilyChatBadge({
    super.key,
    required this.householdId,
    this.selected = false,
  });

  final String householdId;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final stateStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chatState')
        .doc('family')
        .snapshots();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stateStream,
      builder: (context, stateSnapshot) {
        final lastRead =
            stateSnapshot.data?.data()?['lastReadAt'] as Timestamp?;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('households')
              .doc(householdId)
              .collection('messages')
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, messagesSnapshot) {
            final unread =
                messagesSnapshot.data?.docs.where((doc) {
                  final data = doc.data();
                  if (data['senderId'] == uid) return false;
                  final createdAt = data['createdAt'] as Timestamp?;
                  return createdAt != null &&
                      (lastRead == null || createdAt.compareTo(lastRead) > 0);
                }).length ??
                0;
            return Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: Icon(
                selected ? Icons.chat_bubble : Icons.chat_bubble_outline,
              ),
            );
          },
        );
      },
    );
  }
}
