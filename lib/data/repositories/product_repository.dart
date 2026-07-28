import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../models/product_analysis_model.dart';

class ProductRepository {
  ProductRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ProductAnalysisModel> analyzeProduct({
    required String productName,
    String? imagePath,
    double? budget,
  }) async {
    final prompt = _buildPrompt(productName: productName, imagePath: imagePath, budget: budget);

    final response = await _sendRequest(prompt: prompt, imagePath: imagePath);
    return _parseResponse(response);
  }

  String _buildPrompt({
    required String productName,
    String? imagePath,
    double? budget,
  }) {
    return '''
You are a smart buyer assistant.
Return ONLY a single plain JSON object matching this exact shape with no markdown code fences, no commentary, and no extra text:
{
  "productName": "",
  "estimatedPriceNew": 0,
  "estimatedPriceUsed": 0,
  "currency": "YER",
  "advantages": ["", "", ""],
  "disadvantages": ["", "", ""],
  "recommendedProducts": [
    {
      "name": "",
      "newPrice": 0,
      "usedPrice": 0,
      "advantages": [],
      "disadvantages": []
    }
  ]
}

Product: $productName
Budget: ${budget ?? 'not provided'}
Image provided: ${imagePath != null ? 'yes' : 'no'}
''';
  }

  Future<http.Response> _sendRequest({
    required String prompt,
    String? imagePath,
  }) async {
    if (AppConfig.geminiApiKey.isEmpty) {
      return http.Response(
        jsonEncode({
          'productName': 'Sample Product',
          'estimatedPriceNew': 150000,
          'estimatedPriceUsed': 90000,
          'currency': 'YER',
          'advantages': ['Reliable', 'Good value', 'Widely available'],
          'disadvantages': ['Needs maintenance', 'May have old features'],
          'recommendedProducts': []
        }),
        200,
      );
    }

    final uri = Uri.parse(AppConfig.geminiBaseUrl).replace(queryParameters: {
      'key': AppConfig.geminiApiKey,
    });

    final requestBody = {
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
              body: jsonEncode(requestBody),
            )
            .timeout(AppConfig.requestTimeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
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
      }
    }

    throw const ApiException('Unable to process the request.');
  }

  ProductAnalysisModel _parseResponse(http.Response response) {
    try {
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

      final cleaned = _extractJson(text);
      if (cleaned.isEmpty) {
        throw const InvalidJsonException('The AI response was invalid.');
      }

      final data = jsonDecode(cleaned);
      if (data is! Map<String, dynamic>) {
        throw const InvalidJsonException('The AI response was invalid.');
      }
      return ProductAnalysisModel.fromJson(data);
    } on FormatException {
      throw const InvalidJsonException('The AI response was invalid.');
    }
  }

  String _extractJson(String input) {
    final normalized = input.trim();
    final fencedMatch = RegExp(r'```(?:json)?\s*(\{[\s\S]*\})\s*```', caseSensitive: false)
        .firstMatch(normalized);
    if (fencedMatch != null) {
      return fencedMatch.group(1)!.trim();
    }

    final start = normalized.indexOf('{');
    if (start == -1) {
      return '';
    }

    var depth = 0;
    var inString = false;
    var escaped = false;

    for (var i = start; i < normalized.length; i++) {
      final char = normalized[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (inString) {
        continue;
      }

      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) {
          return normalized.substring(start, i + 1).trim();
        }
      }
    }

    return '';
  }
}
