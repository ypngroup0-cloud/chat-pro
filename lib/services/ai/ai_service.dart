import 'package:flutter_riverpod/flutter_riverpod.dart';

// Enum for supported AI providers
enum AIProvider { openai, gemini, deepseek, grok }

// Request Data
class ChatRequest {
  final String message;
  final String systemPrompt;
  final List<String> context; // Knowledge base context
  final AIProvider provider;

  ChatRequest({
    required this.message,
    required this.systemPrompt,
    this.context = const [],
    required this.provider,
  });
}

// Response Data
class ChatResponse {
  final String text;
  final bool isError;
  final String? errorMessage;

  ChatResponse({required this.text, this.isError = false, this.errorMessage});
}

// Abstract Service Class
abstract class AIServiceInterface {
  Future<Stream<String>> streamResponse(
    ChatRequest request, {
    required String apiKey,
  });
}

// Implementation Placeholder (Will be filled later)
class BaseAIService implements AIServiceInterface {
  @override
  Future<Stream<String>> streamResponse(
    ChatRequest request, {
    required String apiKey,
  }) async {
    // Mock implementation for now
    return Stream.value(
      "Echo: ${request.message} (Provider: ${request.provider.name})",
    );
  }
}

final aiServiceProvider = Provider<AIServiceInterface>((ref) {
  return BaseAIService();
});
