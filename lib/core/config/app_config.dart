import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static String geminiApiKey = dotenv.get('GEMINI_API_KEY', fallback: '');

  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static const Duration requestTimeout = Duration(seconds: 25);
  static const int maxRetries = 2;
}
