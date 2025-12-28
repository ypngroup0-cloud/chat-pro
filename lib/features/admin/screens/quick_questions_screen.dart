import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/storage/storage_service.dart';

// --- Provider for Quick Questions ---
class QuickQuestionsNotifier extends Notifier<List<Map<String, String>>> {
  @override
  List<Map<String, String>> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getQuickQuestions();
  }

  Future<void> addQuestion(
    String question, {
    String category = 'General',
  }) async {
    final newQuestion = {
      'id': const Uuid().v4(),
      'question': question,
      'category': category,
    };

    final updated = [...state, newQuestion];
    state = updated;

    final storage = ref.read(storageServiceProvider);
    await storage.saveQuickQuestions(updated);
  }

  Future<void> updateQuestion(
    String id,
    String newQuestion, {
    String category = 'General',
  }) async {
    final updated = state.map((q) {
      if (q['id'] == id) {
        return {'id': id, 'question': newQuestion, 'category': category};
      }
      return q;
    }).toList();

    state = updated;

    final storage = ref.read(storageServiceProvider);
    await storage.saveQuickQuestions(updated);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<Map<String, String>> items = List.from(state);
    final Map<String, String> item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    state = items;
    final storage = ref.read(storageServiceProvider);
    await storage.saveQuickQuestions(items);
  }

  Future<void> deleteQuestion(String id) async {
    final updated = state.where((q) => q['id'] != id).toList();
    state = updated;

    final storage = ref.read(storageServiceProvider);
    await storage.saveQuickQuestions(updated);
  }
}

final quickQuestionsProvider =
    NotifierProvider<QuickQuestionsNotifier, List<Map<String, String>>>(
      QuickQuestionsNotifier.new,
    );

// --- Screen ---
class QuickQuestionsScreen extends ConsumerStatefulWidget {
  const QuickQuestionsScreen({super.key});

  @override
  ConsumerState<QuickQuestionsScreen> createState() =>
      _QuickQuestionsScreenState();
}

class _QuickQuestionsScreenState extends ConsumerState<QuickQuestionsScreen> {
  void _showAddEditDialog({
    String? id,
    String? currentQuestion,
    String? currentCategory,
  }) {
    final controller = TextEditingController(text: currentQuestion ?? '');
    String selectedCategory = currentCategory ?? 'General';
    final categories = ['General', 'Pricing', 'Technical', 'Hours', 'Other'];
    final isEdit = id != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Text(
            isEdit ? 'Edit Question' : 'Add Quick Question',
            style: const TextStyle(color: AppColors.textWhite),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: InputDecoration(
                  hintText: 'Enter question...',
                  hintStyle: TextStyle(
                    color: AppColors.textGrey.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundBlack,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: AppColors.surfaceDark,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: AppColors.textGrey),
                  filled: true,
                  fillColor: AppColors.backgroundBlack,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedCategory = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final question = controller.text.trim();
                if (question.isNotEmpty) {
                  if (isEdit) {
                    ref
                        .read(quickQuestionsProvider.notifier)
                        .updateQuestion(
                          id,
                          question,
                          category: selectedCategory,
                        );
                  } else {
                    ref
                        .read(quickQuestionsProvider.notifier)
                        .addQuestion(question, category: selectedCategory);
                  }
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.black,
              ),
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String id, String question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Delete Question',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: Text(
          'Are you sure you want to delete this question?\n\n"$question"',
          style: const TextStyle(color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(quickQuestionsProvider.notifier).deleteQuestion(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(quickQuestionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Questions',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Predefined questions for customer chat.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(LucideIcons.plus),
              label: const Text("Add Question"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                            LucideIcons.helpCircle,
                            size: 80,
                            color: AppColors.textGrey.withOpacity(0.3),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 2000.ms)
                          .shake(duration: 1000.ms, delay: 2000.ms),
                      const SizedBox(height: 24),
                      Text(
                        'No quick questions yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textGrey.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click "Add Question" to create your first one',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: questions.length,
                  onReorder: (oldIndex, newIndex) {
                    ref
                        .read(quickQuestionsProvider.notifier)
                        .reorder(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    final id = question['id']!;
                    final text = question['question']!;
                    final category = question['category'] ?? 'General';

                    return Container(
                          key: ValueKey(id),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                LucideIcons.gripVertical,
                                color: AppColors.primaryGreen,
                                size: 20,
                              ),
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    category.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  text,
                                  style: const TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.edit2,
                                    color: AppColors.primaryGreen,
                                    size: 20,
                                  ),
                                  onPressed: () => _showAddEditDialog(
                                    id: id,
                                    currentQuestion: text,
                                    currentCategory: category,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _showDeleteConfirmation(id, text),
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                        .slideX(begin: -0.1, end: 0);
                  },
                ),
        ),
      ],
    );
  }
}
