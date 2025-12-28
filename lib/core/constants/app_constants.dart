import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'ProChat Admin';
  static const String defaultBotName = 'Customer Support Bot';
  static const String defaultWelcomeMessage =
      'Hello! How can I help you today?';

  // Storage Keys
  static const String keyApiKeys = 'api_keys';
  static const String keyBotSettings = 'bot_settings';
  static const String keyKnowledgeBase = 'knowledge_base';
  static const String keyQuickQuestions = 'quick_questions';
  static const String keyAdminPassword = 'admin_password';
  static const String keyChatHistory = 'chat_history';
  static const String keyAnalytics = 'analytics';
}

class AppColors {
  // The primary green requested by the user
  static const Color primaryGreen = Color(0xFF00FF00);

  // Dark background colors
  static const Color backgroundBlack = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardColor = Color(0xFF2C2C2C);

  // Text colors
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.grey;
}
