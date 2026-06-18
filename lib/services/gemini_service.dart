import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as direct_ai;

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  void initialize() {}

  Future<String> getResponse({
    required String prompt,
    Map<String, dynamic>? context,
    bool isChat = true,
  }) async {
    final week = await _pregnancyWeek();
    const buildApiKey = String.fromEnvironment('GEMINI_API_KEY');
    final apiKey = buildApiKey.isNotEmpty
        ? buildApiKey
        : dotenv.env['GEMINI_API_KEY'] ?? '';
    final String text;
    if (apiKey.isNotEmpty) {
      text = await _directResponse(prompt, week, apiKey);
    } else {
      text = await _firebaseResponse(prompt, week);
    }
    await _consumeDailyQuota();
    return text;
  }

  Future<String> _firebaseResponse(String prompt, int week) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash-lite',
      systemInstruction: Content.system(
        'You are Bebezen, a maternal-health education assistant. '
        'The user is at pregnancy week $week. Give concise, compassionate, '
        'evidence-aligned information in the same language as the user. '
        'Never diagnose or prescribe. Clearly identify urgent warning signs '
        'and recommend a healthcare professional when appropriate.',
      ),
      generationConfig: GenerationConfig(
        temperature: 0.35,
        maxOutputTokens: 700,
      ),
    );
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw StateError('No assistant response was generated.');
    }
    return text;
  }

  Future<String> _directResponse(String prompt, int week, String apiKey) async {
    final model = direct_ai.GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
      systemInstruction: direct_ai.Content.system(
        'You are Bebezen, a maternal-health education assistant. '
        'The user is at pregnancy week $week. Give concise, compassionate, '
        'evidence-aligned information in the same language as the user. '
        'Never diagnose or prescribe. Clearly identify urgent warning signs '
        'and recommend a healthcare professional when appropriate.',
      ),
      generationConfig: direct_ai.GenerationConfig(
        temperature: 0.35,
        maxOutputTokens: 700,
      ),
    );
    final response = await model.generateContent([
      direct_ai.Content.text(prompt),
    ]);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw StateError('No assistant response was generated.');
    }
    return text;
  }

  Future<int> _pregnancyWeek() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final householdId = user.data()?['householdId'] as String?;
    if (householdId == null) return 0;
    final household = await FirebaseFirestore.instance
        .collection('households')
        .doc(householdId)
        .get();
    final pregnancy = Map<String, dynamic>.from(
      household.data()?['pregnancy'] as Map? ?? {},
    );
    final initial = pregnancy['gestationalAgeWeeks'] as int? ?? 0;
    final reference = pregnancy['referenceDate'] as Timestamp?;
    if (reference == null) return initial;
    return (initial + DateTime.now().difference(reference.toDate()).inDays ~/ 7)
        .clamp(0, 42);
  }

  Future<void> _consumeDailyQuota() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();
    final day =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('usage')
        .doc(day);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final count = snapshot.data()?['assistantCount'] as int? ?? 0;
      if (count >= 10) {
        throw StateError('Daily assistant limit reached.');
      }
      transaction.set(ref, {
        'assistantCount': count + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  bool get isInitialized => true;
}
