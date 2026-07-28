import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_localizations.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  static const _storageKey = 'ai_chat_history';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? <String>[];
    if (!mounted) return;
    setState(() {
      _messages.clear();
      for (final entry in raw) {
        final parts = entry.split('|');
        if (parts.length == 2) {
          _messages.add(_ChatMessage(isUser: parts[0] == 'user', text: parts[1]));
        }
      }
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _messages.map((message) => '${message.isUser ? 'user' : 'ai'}|${message.text}').toList();
    await prefs.setStringList(_storageKey, encoded);
  }

  Future<void> _clearHistory() async {
    setState(() {
      _messages.clear();
    });
    await _saveHistory();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _isLoading = true;
      _controller.clear();
    });
    await _saveHistory();

    try {
      final response = await _callGemini(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: response));
      });
      await _saveHistory();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: 'Sorry, I could not respond right now.'));
      });
      await _saveHistory();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _callGemini(String userText) async {
    final apiKey = dotenv.get('GEMINI_API_KEY', fallback: '');
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key is not configured.');
    }

    final uri = Uri.parse('${AppConfig.geminiBaseUrl}?key=$apiKey');

    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(userText);
    final instruction = isArabic
        ? 'You are a helpful shopping assistant. Respond in Arabic. Keep the answer concise and friendly.'
        : 'You are a helpful shopping assistant. Respond in English. Keep the answer concise and friendly.';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': '$instruction\n\nUser message: $userText'}
          ]
        }
      ]
    });

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gemini request failed');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No candidates returned');
    }

    final content = candidates.first['content'];
    if (content is! Map<String, dynamic>) {
      throw Exception('Invalid response structure');
    }

    final parts = content['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw Exception('No content parts returned');
    }

    final text = parts.first['text'];
    if (text is! String) {
      throw Exception('Invalid response text');
    }

    return text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('app_title')),
        actions: [
          IconButton(
            onPressed: _clearHistory,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildAssistantBubble('Thinking...');
                }
                final message = _messages[index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: message.isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask the AI assistant...',
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: _isLoading ? null : _sendMessage,
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 28, width: 28, child: Lottie.asset('assets/json/ai.json')),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  _ChatMessage({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}
