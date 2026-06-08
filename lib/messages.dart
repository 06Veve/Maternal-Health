
// -------------------------------
// IMPORTS
// -------------------------------
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔁 Firebase core + Firebase AI Logic (nouveau SDK unifié)
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'firebase_options.dart';

// (facultatif) tes autres pages
// import 'package:bebezen/profile.dart';

// -------------------------------
// MESSAGE PAGE
// -------------------------------
class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  // Controllers
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  // Data
  final List<ChatMessage> _messages = [];
  Uint8List? _selectedImage;

  // States
  bool _isLoading = false;
  bool _isGeminiReady = false;

  // Firebase AI Logic - Generative Model
  late GenerativeModel _model;

  // Debounce
  Timer? _debounceTimer;

  // Daily credits
  int _dailyCredits = 10;
  final int _maxCredits = 10;

  @override
  void initState() {
    super.initState();
    _initializeDailyCredits();
    _safeInitFirebaseAndGemini();
    _loadMessages();
  }

  // -------------------------------
  // INITIALIZATION
  // -------------------------------
  Future<void> _safeInitFirebaseAndGemini() async {
    try {
      // Initialise Firebase si ce n'est pas déjà fait (sécurisé)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Initialise le modèle (nvx SDK) – pas de clé API dans le code
      _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash', // modèle recommandé
      );

      setState(() => _isGeminiReady = true);
    } catch (e) {
      setState(() => _isGeminiReady = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialisation AI échouée: $e')),
        );
      }
    }
  }

  Future<void> _initializeDailyCredits() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastReset = prefs.getString('credit_reset_date');

    if (lastReset == null || lastReset != today) {
      _dailyCredits = _maxCredits;
      await prefs.setInt('daily_credits', _dailyCredits);
      await prefs.setString('credit_reset_date', today);
    } else {
      _dailyCredits = prefs.getInt('daily_credits') ?? _maxCredits;
    }

    setState(() {});
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('chat_messages');

    if (messagesJson != null) {
      final decoded = jsonDecode(messagesJson) as List<dynamic>;
      setState(() {
        _messages
          ..clear()
          ..addAll(decoded.map((msg) {
            final message = ChatMessage.fromJson(msg);
            message.animatedText = message.text; // pas d'animation au reload
            return message;
          }));
      });
      _scrollToBottom();
    }
  }

  // -------------------------------
  // MESSAGES MANAGEMENT
  // -------------------------------
  Future<void> _saveMessages() async {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final encoded = jsonEncode(_messages.map((m) => m.toJson()).toList());
        await prefs.setString('chat_messages', encoded);
      } catch (e) {
        debugPrint('❌ Erreur sauvegarde: $e');
      }
    });
  }

  Future<void> _clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_messages');
    setState(() => _messages.clear());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // -------------------------------
  // IMAGE HANDLING
  // -------------------------------
  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _selectedImage = bytes);
    }
  }

  Future<String> saveImageToFile(Uint8List imageBytes) async {
    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
    return filePath;
  }

  // -------------------------------
  // MESSAGE SENDING (Firebase AI)
// -------------------------------
  Future<void> _sendMessage() async {
    FocusScope.of(context).unfocus();
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    if (!_isGeminiReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le modèle n’est pas prêt.')),
      );
      return;
    }

    if (_dailyCredits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous avez épuisé vos crédits journaliers."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    String? savedImagePath;
    if (_selectedImage != null) {
      savedImagePath = await saveImageToFile(_selectedImage!);
    }

    setState(() {
      final newMessage = ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
        imagePath: savedImagePath,
      );
      newMessage.animatedText = userMessage;
      _messages.add(newMessage);
      _isLoading = true;
      _messageController.clear();
    });

    _saveMessages();
    _scrollToBottom();
    await _consumeCredit();

    try {
      // Historique minimal + nouveau contenu multimodal
      final contents = <Content>[
        // contexte système léger (optionnel)
        Content.text(
            "Tu es Chat IA Assistant, un assistant intelligent conçu pour aider les femmes enceintes uniquement."),

        Content.text(userMessage),
      ];

      final response = await _model.generateContent(contents);
      final botText = response.text ?? "Je n'ai pas pu générer de réponse.";

      setState(() {
        _messages.add(ChatMessage(
          text: botText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: 'Erreur: $e',
          isUser: false,
          isError: true,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _selectedImage = null);
      }
    }
  }

  Future<void> _consumeCredit() async {
    if (_dailyCredits > 0) {
      setState(() => _dailyCredits--);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_credits', _dailyCredits);
    }
  }

  // -------------------------------
  // UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.pink,
              radius: 20,
              child: Icon(Icons.psychology, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              _isGeminiReady ? "AI Health Assistant" : "AI (init...)",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Ajouter une image',
              onPressed: _selectImage,
              icon: const Icon(Icons.image_outlined),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pink[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              children: [
                Icon(Icons.favorite, color: Colors.pink),
                SizedBox(width: 12),
                Text("I'm here to support your pregnancy journey!"),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: ChatBubble(message: message),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Type your message...",
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.pink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// -------------------------------
// CHAT MESSAGE MODEL
// -------------------------------
class ChatMessage {
  final String text;
  final DateTime timestamp;
  final bool isUser;
  final bool isError;
  String? animatedText;
  String? imagePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.animatedText,
    this.imagePath,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
  );

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };
}

// -------------------------------
// CHAT BUBBLE WIDGET
// -------------------------------
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      padding: const EdgeInsets.all(14),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: message.isUser ? Colors.pink[100] : Colors.purple[100],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(message.isUser ? 18 : 2),
          bottomRight: Radius.circular(message.isUser ? 2 : 18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.imagePath != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(message.imagePath!),
                width: 180,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 40),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(message.text, style: const TextStyle(fontSize: 16)),
          Text(
            "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
