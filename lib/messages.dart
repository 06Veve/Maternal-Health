import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/features/partner/couple_chat.dart';
import 'package:bebezen/services/gemini_service.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  int? _remaining;

  CollectionReference<Map<String, dynamic>> get _messages {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('aiChats')
        .doc('main')
        .collection('messages');
  }

  Future<void> _send([String? suggestedPrompt]) async {
    final prompt = (suggestedPrompt ?? _controller.text).trim();
    if (prompt.isEmpty || _sending) return;
    FocusScope.of(context).unfocus();
    _controller.clear();
    setState(() => _sending = true);
    try {
      await _messages.add({
        'text': prompt,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      final answer = await GeminiService().getResponse(prompt: prompt);
      await _messages.add({
        'text': answer,
        'role': 'assistant',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _remaining = (_remaining ?? 10) - 1);
    } on GeminiServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    } on StateError catch (error) {
      if (!mounted) return;
      final message = error.message.contains('limit')
          ? 'Your 10 daily questions have been used. Try again tomorrow.'
          : error.message;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to contact the assistant. Check your connection.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _clearConversation() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear conversation?'),
        content: const Text(
          'This removes the assistant conversation from your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    final snapshot = await _messages.limit(100).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bebezen Assistant'),
            Text(
              'Maternal health information',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Family chat',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CoupleChatPage()),
            ),
            icon: const Icon(Icons.family_restroom),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') _clearConversation();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text('Clear conversation')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BebezenPalette.primaryLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  color: BebezenPalette.primary,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Educational support only. Contact a healthcare professional for medical concerns.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                if (_remaining != null)
                  Text(
                    '$_remaining left',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messages
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const BZLoading();
                }
                if (snapshot.data!.docs.isEmpty) {
                  return _EmptyAssistant(onPrompt: _send);
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) =>
                      _AssistantBubble(data: snapshot.data!.docs[index].data()),
                );
              },
            ),
          ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Preparing a careful response…'),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: BebezenPalette.divider)),
              ),
              child: Row(
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
                        hintText: 'Ask about pregnancy…',
                        counterText: '',
                        filled: false,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.arrow_upward_rounded),
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

class _EmptyAssistant extends StatelessWidget {
  const _EmptyAssistant({required this.onPrompt});
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    const prompts = [
      'What changes are common this week?',
      'How can I manage nausea safely?',
      'Which warning signs need urgent care?',
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 28),
        const CircleAvatar(
          radius: 34,
          backgroundColor: BebezenPalette.primaryLight,
          child: Icon(
            Icons.auto_awesome,
            size: 32,
            color: BebezenPalette.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'How can I help today?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Ask a question or start with one of these suggestions.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ...prompts.map(
          (prompt) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              onPressed: () => onPrompt(prompt),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(prompt),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final mine = data['role'] == 'user';
    final timestamp = data['createdAt'] as Timestamp?;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .84,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: mine ? BebezenPalette.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(mine ? 20 : 4),
            bottomRight: Radius.circular(mine ? 4 : 20),
          ),
          border: mine ? null : Border.all(color: BebezenPalette.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  'Bebezen',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: BebezenPalette.primary,
                  ),
                ),
              ),
            Text(
              data['text'] ?? '',
              style: TextStyle(
                color: mine ? Colors.white : BebezenPalette.textPrimary,
                height: 1.4,
              ),
            ),
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  DateFormat('HH:mm').format(timestamp.toDate()),
                  style: TextStyle(
                    fontSize: 10,
                    color: mine ? Colors.white70 : BebezenPalette.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
