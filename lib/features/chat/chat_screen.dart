import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../services/storage/storage_service.dart';
import '../admin/screens/settings_screen.dart';
import 'chat_service.dart';

class ChatMessagesNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    final storage = ref.watch(storageServiceProvider);
    final history = storage.getChatHistory();
    return history.map((e) => ChatMessage.fromJson(e)).toList();
  }

  void update(List<ChatMessage> Function(List<ChatMessage>) updateFn) {
    state = updateFn(state);
    final storage = ref.read(storageServiceProvider);
    storage.saveChatHistory(state.map((m) => m.toJson()).toList());
  }

  void clearHistory() {
    state = [];
    final storage = ref.read(storageServiceProvider);
    storage.clearChatHistory();
  }
}

final chatMessagesProvider =
    NotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(
      ChatMessagesNotifier.new,
    );

class IsTypingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  set value(bool val) => state = val;
}

final isTypingProvider = NotifierProvider<IsTypingNotifier, bool>(
  IsTypingNotifier.new,
);

// --- Screen ---
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();

    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    ref
        .read(chatMessagesProvider.notifier)
        .update((state) => [...state, userMsg]);
    ref.read(isTypingProvider.notifier).value = true;
    _scrollToBottom();

    final messages = ref.read(chatMessagesProvider);
    // History should not include the current message as the service adds it
    final history = messages
        .take(messages.length - 1)
        .map(
          (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
        )
        .toList();

    try {
      final responseText = await ref
          .read(chatServiceProvider)
          .sendMessage(text, history);

      final botMsg = ChatMessage(
        id: const Uuid().v4(),
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      ref
          .read(chatMessagesProvider.notifier)
          .update((state) => [...state, botMsg]);
    } catch (e) {
      final errorMsg = ChatMessage(
        id: const Uuid().v4(),
        text: "Error: ${e.toString().replaceAll('Exception: ', '')}",
        isUser: false,
        timestamp: DateTime.now(),
      );
      ref
          .read(chatMessagesProvider.notifier)
          .update((state) => [...state, errorMsg]);
    } finally {
      ref.read(isTypingProvider.notifier).value = false;
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Show quick question bottom sheet
  void _showQuickQuestions() {
    final storage = ref.read(storageServiceProvider);
    final quickQuestions = storage.getQuickQuestions();

    if (quickQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No quick questions available. Please add some in the admin panel.',
          ),
        ),
      );
      return;
    }

    // Grouping by category
    final Map<String, List<Map<String, String>>> grouped = {};
    for (var q in quickQuestions) {
      final cat = q['category'] ?? 'General';
      grouped.putIfAbsent(cat, () => []).add(q);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.helpCircle,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Questions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                      Text(
                        'Select a common question to get started',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...entry.value.map((q) {
                        final question = q['question'] ?? '';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundBlack,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              question,
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 15,
                              ),
                            ),
                            trailing: const Icon(
                              LucideIcons.chevronRight,
                              color: AppColors.textGrey,
                              size: 18,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _inputController.text = question;
                              _sendMessage();
                            },
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isTyping = ref.watch(isTypingProvider);
    final settings = ref.watch(botSettingsProvider);
    final botName = settings['name'] ?? 'Customer Support';
    final logoBase64 = settings['logo_base64'];

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryGreen,
                    backgroundImage:
                        (logoBase64 != null && logoBase64.isNotEmpty)
                        ? MemoryImage(base64Decode(logoBase64))
                        : null,
                    child: (logoBase64 == null || logoBase64.isEmpty)
                        ? const Icon(
                            LucideIcons.bot,
                            color: Colors.black,
                            size: 20,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        botName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .shimmer(duration: 1500.ms, color: Colors.white54)
                              .scale(
                                duration: 1000.ms,
                                begin: const Offset(1, 1),
                                end: const Offset(1.2, 1.2),
                                curve: Curves.easeInOut,
                              )
                              .then()
                              .scale(
                                duration: 1000.ms,
                                begin: const Offset(1.2, 1.2),
                                end: const Offset(1, 1),
                              ),
                          const SizedBox(width: 8),
                          const Text(
                            'Online',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.trash2,
                      color: Colors.grey,
                      size: 20,
                    ),
                    tooltip: 'Clear Chat',
                    onPressed: () {
                      ref.read(chatMessagesProvider.notifier).clearHistory();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Messages
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(context, ref)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    itemCount: messages.length + (isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                            bottom: 20.0,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceDark,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: List.generate(
                                    3,
                                    (i) =>
                                        Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 2,
                                                  ),
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: AppColors.primaryGreen,
                                                shape: BoxShape.circle,
                                              ),
                                            )
                                            .animate(
                                              onPlay: (controller) =>
                                                  controller.repeat(),
                                            )
                                            .scale(
                                              delay: (i * 150).ms,
                                              duration: 400.ms,
                                              begin: const Offset(1, 1),
                                              end: const Offset(1.5, 1.5),
                                            )
                                            .then()
                                            .scale(
                                              duration: 400.ms,
                                              begin: const Offset(1.5, 1.5),
                                              end: const Offset(1, 1),
                                            ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn();
                      }

                      final msg = messages[index];
                      return Align(
                            alignment: msg.isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: msg.isUser
                                    ? AppColors.primaryGreen
                                    : AppColors.surfaceDark,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: msg.isUser
                                      ? const Radius.circular(16)
                                      : Radius.zero,
                                  bottomRight: msg.isUser
                                      ? Radius.zero
                                      : const Radius.circular(16),
                                ),
                              ),
                              child: msg.isUser
                                  ? Text(
                                      msg.text,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        MarkdownBody(
                                          data: msg.text,
                                          styleSheet:
                                              MarkdownStyleSheet.fromTheme(
                                                Theme.of(context),
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: IconButton(
                                            icon: const Icon(
                                              LucideIcons.copy,
                                              size: 14,
                                              color: AppColors.textGrey,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              Clipboard.setData(
                                                ClipboardData(text: msg.text),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Response copied!',
                                                  ),
                                                  duration: Duration(
                                                    seconds: 1,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          )
                          .animate()
                          .fade(duration: 300.ms)
                          .slideY(begin: 0.1, end: 0);
                    },
                  ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      fillColor: AppColors.backgroundBlack,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Quick Question Button
                IconButton(
                  icon: const Icon(
                    LucideIcons.helpCircle,
                    color: AppColors.primaryGreen,
                  ),
                  tooltip: 'Quick Questions',
                  onPressed: _showQuickQuestions,
                ),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  mini: true,
                  child: const Icon(LucideIcons.send, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(botSettingsProvider);
    final welcome =
        settings['welcome_message'] ?? AppConstants.defaultWelcomeMessage;
    final quickQuestions = ref
        .watch(storageServiceProvider)
        .getQuickQuestions();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.bot,
                color: AppColors.primaryGreen,
                size: 48,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              welcome,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 12),
            const Text(
              "How can I help you today? Choose a question below or type your own.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 48),
            if (quickQuestions.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Suggested Questions",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: quickQuestions.take(4).map((q) {
                  return _QuickActionChip(
                    label: q['question'] ?? '',
                    onTap: () {
                      _inputController.text = q['question'] ?? '';
                      _sendMessage();
                    },
                  );
                }).toList(),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}
