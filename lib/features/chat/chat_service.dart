import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage/storage_service.dart';
import '../../features/admin/models/api_key_model.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ChatService(storage);
});

// --- Models ---
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

// --- Service ---
class ChatService {
  final StorageService _storage;

  ChatService(this._storage);

  Future<String> sendMessage(
    String message,
    List<Map<String, String>> history,
  ) async {
    final settings = _storage.getBotSettings();
    final systemPrompt =
        settings['system_prompt'] ?? 'You are a helpful assistant.';

    final kb = _storage.getKnowledgeBase();
    String context = "";
    if (kb.isNotEmpty) {
      context = "\n\nRelevant Context (Use this to answer if relevant):\n";
      for (var item in kb) {
        context += "- ${item['title']}: ${item['content']}\n";
      }
    }

    final allKeysRaw = _storage.getApiKeys();
    final allKeys = allKeysRaw.map((e) => ApiKeyModel.fromJson(e)).toList();
    List<ApiKeyModel> activeKeys = allKeys
        .where((k) => k.isEffectivelyActive)
        .toList();

    if (activeKeys.isEmpty) {
      throw Exception('No active API keys found. Please contact admin.');
    }

    // Sort to use keys with least usage first to balance load
    activeKeys.sort((a, b) => a.usageCount.compareTo(b.usageCount));

    String? lastError;
    for (var apiKey in activeKeys) {
      try {
        String response;
        if (apiKey.provider == 'gemini') {
          response = await _callGemini(
            apiKey.key,
            systemPrompt,
            context,
            message,
            history,
          );
        } else if (apiKey.provider == 'openai' ||
            apiKey.provider == 'deepseek' ||
            apiKey.provider == 'grok') {
          response = await _callOpenAICompatible(
            apiKey,
            systemPrompt,
            context,
            message,
            history,
          );
        } else {
          continue;
        }

        // Increment usage count and update ONLY the specific key in the full list
        final updatedKeys = allKeys.map((k) {
          if (k.key == apiKey.key) {
            return k.copyWith(usageCount: k.usageCount + 1);
          }
          return k;
        }).toList();

        await _storage.saveApiKeys(updatedKeys.map((e) => e.toJson()).toList());

        // Update Analytics
        await _storage.incrementAnalytic('total_messages');
        if (history.isEmpty) {
          await _storage.incrementAnalytic('total_chats');
        }

        return response;
      } catch (e) {
        lastError = e.toString();
        // If it's a quota, auth, or balance error, mark as failed
        if (lastError.contains('429') ||
            lastError.contains('quota') ||
            lastError.contains('401') ||
            lastError.contains('402') ||
            lastError.contains('balance') ||
            lastError.contains('invalid_api_key')) {
          _markKeyAsFailed(apiKey.key);
        }
        continue; // Try next key
      }
    }

    throw Exception(
      'All API keys failed. Suggestion: Check if your API keys are correct and have remaining quota.\n\nDetails: $lastError',
    );
  }

  Future<bool> testConnection(ApiKeyModel apiKey) async {
    try {
      final systemPrompt = "You are a test assistant.";
      final context = "";
      final history = <Map<String, String>>[];
      final message = "Hello, are you working?";

      String response;
      if (apiKey.provider == 'gemini') {
        response = await _callGemini(
          apiKey.key,
          systemPrompt,
          context,
          message,
          history,
        );
      } else {
        response = await _callOpenAICompatible(
          apiKey,
          systemPrompt,
          context,
          message,
          history,
        );
      }
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _markKeyAsFailed(String key) async {
    final allKeysRaw = _storage.getApiKeys();
    final updatedKeys = allKeysRaw.map((e) {
      final model = ApiKeyModel.fromJson(e);
      if (model.key == key) {
        return model
            .copyWith(
              // Keep isActive as true so it can recover after cooldown
              // A manual toggle can still set isActive to false
              cooldownUntil: DateTime.now().add(const Duration(hours: 1)),
            )
            .toJson();
      }
      return e;
    }).toList();
    await _storage.saveApiKeys(updatedKeys);
  }

  Future<String> _callGemini(
    String key,
    String system,
    String context,
    String userMsg,
    List<Map<String, String>> history,
  ) async {
    // Using gemini-1.5-flash for better performance and higher free tier
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key',
    );

    // Prepare history and current message
    final List<Map<String, dynamic>> contents = [];

    // Add history (mapping roles correctly for Gemini)
    for (var msg in history) {
      final role = msg['role'] == 'user' ? 'user' : 'model';
      contents.add({
        "role": role,
        "parts": [
          {"text": msg['content']},
        ],
      });
    }

    // Add current message with context
    final currentMsgContent = context.isNotEmpty
        ? "Context:\n$context\n\nUser Question: $userMsg"
        : userMsg;

    contents.add({
      "role": "user",
      "parts": [
        {"text": currentMsgContent},
      ],
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "system_instruction": {
          "parts": [
            {"text": system},
          ],
        },
        "contents": contents,
        "generationConfig": {"temperature": 0.7, "maxOutputTokens": 2048},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      try {
        return data['candidates'][0]['content']['parts'][0]['text'];
      } catch (e) {
        throw Exception('Gemini response format error: ${response.body}');
      }
    } else {
      throw Exception('Gemini Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<String> _callOpenAICompatible(
    ApiKeyModel apiKey,
    String system,
    String context,
    String userMsg,
    List<Map<String, String>> history,
  ) async {
    String baseUrl = 'https://api.openai.com/v1/chat/completions';
    String model = 'gpt-4o-mini'; // Better and cheaper than gpt-3.5-turbo

    if (apiKey.provider == 'deepseek') {
      baseUrl = 'https://api.deepseek.com/v1/chat/completions';
      model = 'deepseek-chat';
    } else if (apiKey.provider == 'grok') {
      baseUrl = 'https://api.x.ai/v1/chat/completions';
      model = 'grok-beta';
    }

    final List<Map<String, String>> messages = [
      {"role": "system", "content": "$system\n\n$context"},
    ];

    // Add history
    messages.addAll(history);

    // Add current message
    messages.add({"role": "user", "content": userMsg});

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${apiKey.key}',
      },
      body: jsonEncode({
        "model": model,
        "messages": messages,
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception(
        '${apiKey.provider} Error ${response.statusCode}: ${response.body}',
      );
    }
  }
}
