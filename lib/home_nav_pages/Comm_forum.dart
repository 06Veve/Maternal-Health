// ignore_for_file: file_names

import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _contentController = TextEditingController();
  String _selectedCategory = "General";

  final List<String> _categories = [
    "General",
    "Pregnancy",
    "Nutrition",
    "Mental Health",
    "Baby Care",
  ];

  @override
  void initState() {
    super.initState();
    _backfillOwnPostNames();
  }

  Future<String> _currentUserName(User user) async {
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final name = (profile.data()?['name'] as String?)?.trim();
    return name?.isNotEmpty == true
        ? name!
        : user.displayName ?? user.email?.split('@').first ?? 'Anonymous';
  }

  Future<void> _backfillOwnPostNames() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final name = await _currentUserName(user);
      final posts = await FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: user.uid)
          .limit(50)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      var changed = false;
      for (final post in posts.docs) {
        if (post.data()['username'] != name) {
          batch.update(post.reference, {'username': name});
          changed = true;
        }
      }
      if (changed) await batch.commit();
    } on FirebaseException {
      // Name migration is best-effort and must not block the community feed.
    }
  }

  Future<void> _addPost() async {
    if (_contentController.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final name = await _currentUserName(user);
    await FirebaseFirestore.instance.collection('posts').add({
      'username': name,
      'content': _contentController.text.trim(),
      'category': _selectedCategory,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
      'authorId': user.uid,
    });
    _contentController.clear();
  }

  Future<void> _toggleLike(String postId, bool isLiked) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final like = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(user.uid);
    try {
      if (isLiked) {
        await like.delete();
      } else {
        await like.set({
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to update this like.')),
      );
    }
  }

  void _showReplies(String postId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RepliesSheet(postId: postId),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Forum"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _categories
                  .map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (val) =>
                            setState(() => _selectedCategory = cat),
                        selectedColor: BebezenPalette.primary,
                        labelStyle: TextStyle(
                          color: _selectedCategory == cat
                              ? Colors.white
                              : BebezenPalette.textPrimary,
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: _selectedCategory == cat
                              ? BebezenPalette.primary
                              : BebezenPalette.divider,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('category', isEqualTo: _selectedCategory)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load the community: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) return const BZLoading();
                final docs = [...snapshot.data!.docs]
                  ..sort((a, b) {
                    final aTime =
                        (a.data() as Map<String, dynamic>)['timestamp']
                            as Timestamp?;
                    final bTime =
                        (b.data() as Map<String, dynamic>)['timestamp']
                            as Timestamp?;
                    return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
                      aTime?.millisecondsSinceEpoch ?? 0,
                    );
                  });
                if (docs.isEmpty) {
                  return Center(
                    child: Text("No posts in $_selectedCategory yet."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final postId = docs[index].id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: BZCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: BebezenPalette.primaryLight,
                                  child: Icon(
                                    Icons.person,
                                    color: BebezenPalette.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['username'] ?? 'Anonymous',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      data['timestamp'] is Timestamp
                                          ? DateFormat('d MMM, HH:mm').format(
                                              (data['timestamp'] as Timestamp)
                                                  .toDate(),
                                            )
                                          : 'Just now',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: BebezenPalette.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              data['content'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 16),
                            _PostActions(
                              postId: postId,
                              onLike: _toggleLike,
                              onReplies: () => _showReplies(postId),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPostDialog,
        backgroundColor: BebezenPalette.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showPostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Create Post", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            BZInput(
              label: "Content",
              hint: "What's on your mind?",
              controller: _contentController,
            ),
            const SizedBox(height: 24),
            BZButton(
              label: "Post",
              onPressed: () async {
                try {
                  await _addPost();
                  if (context.mounted) Navigator.pop(context);
                } on FirebaseException catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.message ?? 'Unable to publish this post.',
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.postId,
    required this.onLike,
    required this.onReplies,
  });

  final String postId;
  final Future<void> Function(String postId, bool isLiked) onLike;
  final VoidCallback onReplies;

  @override
  Widget build(BuildContext context) {
    final post = FirebaseFirestore.instance.collection('posts').doc(postId);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Row(
      children: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: post.collection('likes').limit(500).snapshots(),
          builder: (context, snapshot) {
            final likes = snapshot.data?.docs ?? [];
            final isLiked = likes.any((like) => like.id == uid);
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: snapshot.hasData ? () => onLike(postId, isLiked) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 21,
                      color: BebezenPalette.primary,
                    ),
                    const SizedBox(width: 5),
                    Text('${likes.length}'),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: post.collection('replies').limit(500).snapshots(),
          builder: (context, snapshot) => InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onReplies,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 20,
                    color: BebezenPalette.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text('${snapshot.data?.docs.length ?? 0}'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RepliesSheet extends StatefulWidget {
  const _RepliesSheet({required this.postId});

  final String postId;

  @override
  State<_RepliesSheet> createState() => _RepliesSheetState();
}

class _RepliesSheetState extends State<_RepliesSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  CollectionReference<Map<String, dynamic>> get _replies => FirebaseFirestore
      .instance
      .collection('posts')
      .doc(widget.postId)
      .collection('replies');

  Future<void> _send() async {
    final text = _controller.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (text.isEmpty || user == null || _sending) return;
    setState(() => _sending = true);
    try {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final profileName = (profile.data()?['name'] as String?)?.trim();
      final name = profileName?.isNotEmpty == true
          ? profileName!
          : user.displayName ?? user.email?.split('@').first ?? 'Anonymous';
      await _replies.add({
        'text': text,
        'authorId': user.uid,
        'username': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Unable to publish the reply.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: .86,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: BebezenPalette.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text('Replies', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _replies
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Unable to load replies.'));
                  }
                  if (!snapshot.hasData) return const BZLoading();
                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No replies yet. Start the conversation.'),
                    );
                  }
                  return ListView.separated(
                    reverse: true,
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (_, _) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final data = snapshot.data!.docs[index].data();
                      final timestamp = data['createdAt'] as Timestamp?;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: BebezenPalette.primaryLight,
                            child: Icon(
                              Icons.person,
                              size: 19,
                              color: BebezenPalette.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['username'] ?? 'Anonymous',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (timestamp != null)
                                      Text(
                                        DateFormat(
                                          'd MMM, HH:mm',
                                        ).format(timestamp.toDate()),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: BebezenPalette.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(data['text'] ?? ''),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Write a reply…',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
