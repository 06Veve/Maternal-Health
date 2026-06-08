import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({Key? key}) : super(key: key);

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _contentController = TextEditingController();

  /// Get current user's name or email
  String get _currentUserName {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email ?? "Anonymous";
  }

  Future<void> _addPost() async {
    if (_contentController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('posts').add({
      'username': _currentUserName,
      'content': _contentController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
    });

    _contentController.clear();
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEFF5), // soft pink bg
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Community Forum",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.search, color: Colors.black),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  _buildTag("Pregnancy"),
                  _buildTag("Nutrition"),
                  _buildTag("Mental Health"),
                  _buildTag("Baby Care"),
                  _buildTag("General"),
                ],
              ),
            ),
          ),

          // Posts list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                      child: Text("No posts yet. Be the first to share!"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final username = data['username'] ?? 'Anonymous';
                    final content = data['content'] ?? '';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final likes = data['likes'] ?? 0;
                    final comments = data['comments'] ?? 0;

                    final timeText = timestamp == null
                        ? 'sending…'
                        : _formatTime(timestamp.toDate());

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 6,
                            offset: const Offset(2, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User row
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.pinkAccent,
                                child: Icon(Icons.person,
                                    color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(username,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(timeText,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Post content
                          Text(
                            content,
                            style: const TextStyle(fontSize: 15),
                          ),

                          const SizedBox(height: 12),

                          // Actions row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.favorite_border,
                                      size: 20, color: Colors.pink),
                                  const SizedBox(width: 4),
                                  Text("$likes"),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.chat_bubble_outline,
                                      size: 20, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text("$comments"),
                                ],
                              ),
                              const Icon(Icons.share,
                                  size: 20, color: Colors.grey),
                            ],
                          )
                        ],
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
        backgroundColor: Colors.pinkAccent,
        onPressed: _showPostDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: Colors.pink.shade100,
      labelStyle: const TextStyle(color: Colors.black),
    );
  }

  void _showPostDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return Container();
      },
      transitionBuilder: (context, animation1, animation2, child) {
        return Transform.scale(
          scale: animation1.value,
          child: Opacity(
            opacity: animation1.value,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.85,
                decoration: BoxDecoration(
                  color: Theme
                      .of(context)
                      .brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.pinkAccent.withOpacity(0.1),
                            Colors.purpleAccent.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient:  LinearGradient(
                                colors: [
                                  Colors.pinkAccent,
                                  Colors.purpleAccent
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Create Post",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                   /* color: Theme
                                        .of(context)
                                        .brightness == Brightness.dark
                                        ? Colors.white
                                        : const Color(0xFF2D3748),

                                    */
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Share your thoughts with the community",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                            /*  color: Theme
                                  .of(context)
                                  .brightness == Brightness.dark
                                  ? const Color(0xFF2D2D2D)
                                  : const Color(0xFFF7FAFC),

                             */
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _contentController,
                              decoration: InputDecoration(
                                hintText: "What's on your mind?",
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(20),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Theme
                                    .of(context)
                                    .brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF2D3748),
                              ),
                              maxLines: 4,
                              minLines: 3,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.grey.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _addPost();
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ).copyWith(
                                    backgroundColor: MaterialStateProperty.all(
                                        Colors.transparent),
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.pinkAccent,
                                          Colors.purpleAccent
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.pinkAccent.withOpacity(
                                              0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center,
                                        children: const [
                                          Icon(Icons.send_rounded, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            "Post",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}