import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';

class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> generateAnalysis({
    required String prompt,
    String? imagePath,
  }) async {
    if (AppConfig.geminiApiKey.isEmpty) {
      return {
        'productName': 'Sample Product',
        'estimatedPriceNew': 150000,
        'estimatedPriceUsed': 90000,
        'currency': 'YER',
        'advantages': ['Reliable', 'Good value', 'Widely available'],
        'disadvantages': ['Needs maintenance', 'May have old features'],
        'recommendedProducts': []
      };
    }

    final uri = Uri.parse(AppConfig.geminiBaseUrl).replace(queryParameters: {
      'key': AppConfig.geminiApiKey,
    });

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            if (imagePath != null)
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Encode(File(imagePath).readAsBytesSync()),
                }
              },
          ],
        }
      ]
    };

    for (var attempt = 0; attempt <= AppConfig.maxRetries; attempt++) {
      try {
        final response = await _client
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(AppConfig.requestTimeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body);
          if (decoded is! Map<String, dynamic>) {
            throw const InvalidJsonException('The AI response was invalid.');
          }

          final candidates = decoded['candidates'];
          if (candidates is! List || candidates.isEmpty) {
            throw const InvalidJsonException('The AI response was invalid.');
          }

          final firstCandidate = candidates.first;
          if (firstCandidate is! Map<String, dynamic>) {
            throw const InvalidJsonException('The AI response was invalid.');
          }

          final content = firstCandidate['content'];
          if (content is! Map<String, dynamic>) {
            throw const InvalidJsonException('The AI response was invalid.');
          }

          final parts = content['parts'];
          if (parts is! List || parts.isEmpty) {
            throw const InvalidJsonException('The AI response was invalid.');
          }

          final firstPart = parts.first;
          if (firstPart is! Map<String, dynamic>) {
            throw const InvalidJsonException('The AI response was invalid.');
          }

          final text = firstPart['text'];
          if (text is! String) {
            throw const InvalidJsonException('The AI response was invalid.');
          }

          final cleanJson = _extractJson(text);
          if (cleanJson.isEmpty) {
            throw const InvalidJsonException('The AI response was invalid.');
          }

          final parsed = jsonDecode(cleanJson);
          if (parsed is! Map<String, dynamic>) {
            throw const InvalidJsonException('The AI response was invalid.');
          }
          return parsed;
        }

        throw ApiException('Unexpected API response', code: response.statusCode.toString());
      } on SocketException {
        if (attempt == AppConfig.maxRetries) {
          throw const NetworkException('No internet connection available.');
        }
      } on HttpException {
        if (attempt == AppConfig.maxRetries) {
          throw const NetworkException('Unable to reach the server.');
        }
      } on TimeoutException {
        if (attempt == AppConfig.maxRetries) {
          throw const ApiException('Request timed out.');
        }
      } on FormatException {
        if (attempt == AppConfig.maxRetries) {
          throw const InvalidJsonException('The AI response was invalid.');
        }
      }
    }

    throw const ApiException('Unable to process the request.');
  }

  String _extractJson(String input) {
    final start = input.indexOf('{');
    final end = input.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      return '';
    }
    return input.substring(start, end + 1);
  }
}
