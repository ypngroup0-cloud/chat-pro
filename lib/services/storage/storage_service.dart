import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized in main.dart');
});

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // --- API Keys ---
  Future<void> saveApiKeys(List<Map<String, dynamic>> keys) async {
    await _prefs.setString(AppConstants.keyApiKeys, jsonEncode(keys));
  }

  List<Map<String, dynamic>> getApiKeys() {
    final String? jsonStr = _prefs.getString(AppConstants.keyApiKeys);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- Bot Settings ---
  Future<void> saveBotSettings(Map<String, String> settings) async {
    await _prefs.setString(AppConstants.keyBotSettings, jsonEncode(settings));
  }

  Map<String, String> getBotSettings() {
    final String? jsonStr = _prefs.getString(AppConstants.keyBotSettings);
    if (jsonStr == null) return {};

    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return {};
    }
  }

  // --- Knowledge Base ---
  Future<void> saveKnowledgeBase(List<Map<String, String>> items) async {
    await _prefs.setString(AppConstants.keyKnowledgeBase, jsonEncode(items));
  }

  List<Map<String, String>> getKnowledgeBase() {
    final String? jsonStr = _prefs.getString(AppConstants.keyKnowledgeBase);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, String>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- Quick Questions ---
  Future<void> saveQuickQuestions(List<Map<String, String>> questions) async {
    await _prefs.setString(
      AppConstants.keyQuickQuestions,
      jsonEncode(questions),
    );
  }

  List<Map<String, String>> getQuickQuestions() {
    final String? jsonStr = _prefs.getString(AppConstants.keyQuickQuestions);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, String>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- Admin Security ---
  Future<void> saveAdminPassword(String password) async {
    await _prefs.setString(AppConstants.keyAdminPassword, password);
  }

  String? getAdminPassword() {
    return _prefs.getString(AppConstants.keyAdminPassword);
  }

  // --- Customer Chat History ---
  Future<void> saveChatHistory(List<Map<String, dynamic>> messages) async {
    await _prefs.setString(AppConstants.keyChatHistory, jsonEncode(messages));
  }

  List<Map<String, dynamic>> getChatHistory() {
    final String? jsonStr = _prefs.getString(AppConstants.keyChatHistory);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearChatHistory() async {
    await _prefs.remove(AppConstants.keyChatHistory);
  }

  // --- Analytics ---
  Future<void> saveAnalytics(Map<String, int> stats) async {
    await _prefs.setString(AppConstants.keyAnalytics, jsonEncode(stats));
  }

  Map<String, int> getAnalytics() {
    final String? jsonStr = _prefs.getString(AppConstants.keyAnalytics);
    if (jsonStr == null) return {'total_messages': 0, 'total_chats': 0};
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {'total_messages': 0, 'total_chats': 0};
    }
  }

  Future<void> incrementAnalytic(String key) async {
    final stats = getAnalytics();
    stats[key] = (stats[key] ?? 0) + 1;
    await saveAnalytics(stats);
  }

  // --- Export / Import ---
  Map<String, dynamic> exportAllData() {
    return {
      AppConstants.keyApiKeys: getApiKeys(),
      AppConstants.keyBotSettings: getBotSettings(),
      AppConstants.keyKnowledgeBase: getKnowledgeBase(),
      AppConstants.keyQuickQuestions: getQuickQuestions(),
      AppConstants.keyAdminPassword: getAdminPassword(),
      AppConstants.keyAnalytics: getAnalytics(),
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    if (data.containsKey(AppConstants.keyApiKeys)) {
      await saveApiKeys(
        List<Map<String, dynamic>>.from(data[AppConstants.keyApiKeys]),
      );
    }
    if (data.containsKey(AppConstants.keyBotSettings)) {
      await saveBotSettings(
        Map<String, String>.from(data[AppConstants.keyBotSettings]),
      );
    }
    if (data.containsKey(AppConstants.keyKnowledgeBase)) {
      await saveKnowledgeBase(
        List<Map<String, String>>.from(data[AppConstants.keyKnowledgeBase]),
      );
    }
    if (data.containsKey(AppConstants.keyQuickQuestions)) {
      await saveQuickQuestions(
        List<Map<String, String>>.from(data[AppConstants.keyQuickQuestions]),
      );
    }
    if (data.containsKey(AppConstants.keyAdminPassword)) {
      await saveAdminPassword(data[AppConstants.keyAdminPassword]);
    }
    if (data.containsKey(AppConstants.keyAnalytics)) {
      await saveAnalytics(
        Map<String, int>.from(data[AppConstants.keyAnalytics]),
      );
    }
  }
}
