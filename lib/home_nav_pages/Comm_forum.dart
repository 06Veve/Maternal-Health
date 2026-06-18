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

  Future<void> _addPost() async {
    if (_contentController.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('posts').add({
      'username': user.displayName ?? user.email?.split('@')[0] ?? "Anonymous",
      'content': _contentController.text.trim(),
      'category': _selectedCategory,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
      'authorId': user.uid,
    });
    _contentController.clear();
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
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  size: 20,
                                  color: BebezenPalette.primary,
                                ),
                                const SizedBox(width: 4),
                                Text("${data['likes']}"),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 20,
                                  color: BebezenPalette.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text("${data['comments']}"),
                              ],
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
