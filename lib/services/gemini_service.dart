import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiServiceException implements Exception {
  const GeminiServiceException(this.userMessage);

  final String userMessage;

  @override
  String toString() => userMessage;
}

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
    final apiKey =
        (buildApiKey.isNotEmpty
                ? buildApiKey
                : dotenv.env['GEMINI_API_KEY'] ?? '')
            .trim();
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
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-2.5-flash:generateContent',
    );
    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {
                    'text':
                        'You are Bebezen, a maternal-health education '
                        'assistant. The user is at pregnancy week $week. '
                        'Give concise, compassionate, evidence-aligned '
                        'information in the same language as the user. Never '
                        'diagnose or prescribe. Clearly identify urgent '
                        'warning signs and recommend a healthcare professional '
                        'when appropriate.',
                  },
                ],
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {'temperature': 0.35, 'maxOutputTokens': 700},
            }),
          )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GeminiServiceException(_apiErrorMessage(response.statusCode));
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = body['candidates'] as List<dynamic>?;
      final content = candidates?.firstOrNull as Map<String, dynamic>?;
      final parts =
          (content?['content'] as Map<String, dynamic>?)?['parts']
              as List<dynamic>?;
      final text = parts
          ?.whereType<Map<String, dynamic>>()
          .map((part) => part['text'] as String? ?? '')
          .join()
          .trim();
      if (text == null || text.isEmpty) {
        throw const GeminiServiceException(
          'Gemini n’a généré aucune réponse. Reformulez la question.',
        );
      }
      return text;
    } on TimeoutException {
      throw const GeminiServiceException(
        'Gemini met trop de temps à répondre. Réessayez dans un instant.',
      );
    } on http.ClientException {
      throw const GeminiServiceException(
        'Connexion à Gemini impossible. Vérifiez votre accès Internet.',
      );
    } on FormatException {
      throw const GeminiServiceException(
        'Gemini a retourné une réponse illisible. Réessayez.',
      );
    }
  }

  String _apiErrorMessage(int statusCode) {
    return switch (statusCode) {
      400 => 'La requête Gemini ou la clé API est invalide.',
      401 || 403 =>
        'La clé Gemini est refusée. Vérifiez qu’elle vient de Google AI Studio '
            'et que la Gemini API est autorisée.',
      404 => 'Le modèle Gemini demandé est indisponible pour ce projet.',
      429 => 'Le quota Gemini est épuisé. Réessayez plus tard.',
      >= 500 => 'Le service Gemini est temporairement indisponible.',
      _ => 'Gemini ne peut pas répondre (erreur $statusCode).',
    };
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
