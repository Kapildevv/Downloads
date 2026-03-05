import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// GeminiService — Secure Gemini API client for Howealthy Oracle 2.0.
///
/// API key is loaded from encrypted Hive box — NEVER hardcoded.
/// System prompt is engineered for Indian personal finance context.
class GeminiService {
  static GenerativeModel? _model;
  static ChatSession? _chatSession;
  static const String _hiveKeyName = 'gemini_api_key';

  /// Indian financial advisor system instruction.
  static const String _systemPrompt = '''
You are Oracle, an expert Indian personal finance advisor built into the Howealthy app. 
Your role is to help Indian users manage their money better.

Rules:
- Always respond in simple, conversational English. Use Hinglish sparingly for warmth.
- All currency is in Indian Rupees (₹). Use Indian number formatting (lakhs, crores).
- Reference Indian financial products: PPF, EPF, ELSS, NPS, SIP, RD, FD, Section 80C/80D.
- Reference Indian tax slabs (old vs new regime) when discussing tax saving.
- When suggesting investments, mention Indian platforms (Groww, Zerodha, Kuvera).
- Be encouraging but honest about financial health.
- Keep responses concise — max 3 paragraphs.
- Never recommend specific stocks. You can discuss index funds and asset allocation.
- If asked about something outside personal finance, politely redirect.
- Format amounts nicely: ₹1,50,000 not ₹150000.
''';

  /// Checks if a Gemini API key is configured.
  static bool get isConfigured {
    try {
      final box = Hive.box('oracleBox');
      final key = box.get(_hiveKeyName) as String?;
      return key != null && key.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Saves the API key to encrypted Hive storage.
  static Future<void> saveApiKey(String apiKey) async {
    try {
      final box = Hive.box('oracleBox');
      await box.put(_hiveKeyName, apiKey);
      _model = null; // Reset model to pick up new key
      _chatSession = null;
      debugPrint('Gemini API key saved securely.');
    } catch (e) {
      debugPrint('Failed to save Gemini API key: $e');
    }
  }

  /// Retrieves the API key from encrypted Hive storage.
  static String? _getApiKey() {
    try {
      final box = Hive.box('oracleBox');
      return box.get(_hiveKeyName) as String?;
    } catch (e) {
      debugPrint('Failed to retrieve Gemini API key: $e');
      return null;
    }
  }

  /// Initializes the Gemini model (lazy, called on first message).
  static GenerativeModel? _initializeModel() {
    final apiKey = _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('Gemini: No API key configured.');
      return null;
    }

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.text(_systemPrompt),
      generationConfig: GenerationConfig(
        maxOutputTokens: 1024,
        temperature: 0.7,
        topP: 0.9,
      ),
    );
    return _model;
  }

  /// Starts or returns the existing chat session.
  static ChatSession? _getOrCreateChatSession() {
    if (_chatSession != null) return _chatSession;
    final model = _model ?? _initializeModel();
    if (model == null) return null;
    _chatSession = model.startChat();
    return _chatSession;
  }

  /// Sends a message with financial context and returns the response.
  ///
  /// [userMessage]     — the user's question.
  /// [financialContext] — anonymized summary of user's finances (injected as context).
  static Future<String> sendMessage(
    String userMessage, {
    String? financialContext,
  }) async {
    try {
      final chat = _getOrCreateChatSession();
      if (chat == null) {
        return '⚙️ Gemini API key not configured. Go to Settings → Oracle AI → enter your API key.';
      }

      // Prepend financial context if available
      String fullMessage = userMessage;
      if (financialContext != null && financialContext.isNotEmpty) {
        fullMessage = '''
[User's Financial Context — this month]:
$financialContext

User's Question: $userMessage''';
      }

      final response = await chat.sendMessage(Content.text(fullMessage));
      final text = response.text;

      if (text == null || text.isEmpty) {
        return 'Oracle couldn\'t generate a response. Please try rephrasing your question.';
      }

      return text;
    } on GenerativeAIException catch (e) {
      debugPrint('Gemini API error: $e');
      if (e.toString().contains('API_KEY_INVALID')) {
        return '❌ Invalid API key. Please check your Gemini API key in Settings.';
      }
      if (e.toString().contains('RATE_LIMIT')) {
        return '⏳ Too many requests. Please wait a moment and try again.';
      }
      return '⚠️ Oracle is temporarily unavailable: ${e.message}';
    } catch (e) {
      debugPrint('Gemini unexpected error: $e');
      return '⚠️ Connection issue. Please check your internet and try again.';
    }
  }

  /// Resets the chat session (start fresh conversation).
  static void resetChat() {
    _chatSession = null;
    debugPrint('Gemini chat session reset.');
  }
}
