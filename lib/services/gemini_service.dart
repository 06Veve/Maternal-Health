import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:bebezen/services/logger.dart';

/// Gemini AI Service for pregnancy-related advice and support
/// Uses Google Generative AI to provide evidence-based information
class GeminiService {
  late GenerativeModel _model;
  static const String _tag = 'GeminiService';
  static const String _modelName = 'gemini-1.5-flash';

  /// Initialize Gemini service with API key
  /// Make sure to set GEMINI_API_KEY in your environment or pass it here
  void initialize(String apiKey) {
    try {
      _model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
      );
      AppLogger.success('Gemini service initialized', tag: _tag);
    } catch (e, st) {
      AppLogger.error(
        'Failed to initialize Gemini service',
        tag: _tag,
        exception: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Get pregnancy-related advice from Gemini
  /// Returns AI-generated response about pregnancy topics
  Future<String> getPregnancyAdvice(String question) async {
    try {
      AppLogger.info('Getting pregnancy advice for: $question', tag: _tag);

      final systemPrompt = '''You are a helpful pregnancy support assistant. 
Provide evidence-based, compassionate information about pregnancy, 
maternal health, and fetal development. 
Always encourage consulting with healthcare providers for medical concerns.
Keep responses clear, concise, and reassuring.''';

      final response = await _model.generateContent([
        Content.text(systemPrompt),
        Content.text(question),
      ]);

      final result = response.text ?? 'No response received';
      AppLogger.success('Advice generated successfully', tag: _tag);
      return result;
    } catch (e, st) {
      AppLogger.error(
        'Error getting pregnancy advice',
        tag: _tag,
        exception: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Get information about pregnancy milestone
  /// Pass week number to get relevant milestone information
  Future<String> getMilestoneInfo(int weekNumber) async {
    try {
      AppLogger.info(
        'Getting milestone info for week $weekNumber',
        tag: _tag,
      );

      final prompt =
          'Provide a brief, evidence-based summary of fetal development at week $weekNumber of pregnancy. Include size, key developments, and what the mother might experience. Keep it to 2-3 paragraphs.';

      final response = await _model.generateContent([Content.text(prompt)]);

      final result = response.text ?? 'No information available';
      return result;
    } catch (e, st) {
      AppLogger.error(
        'Error getting milestone info',
        tag: _tag,
        exception: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _model != null;
}
