import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/storage/storage_service.dart';

// Simple Model for KB Item
class KbItem {
  final String id;
  final String title;
  final String content;
  final String type; // 'text' or 'link'

  KbItem({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
  });

  Map<String, String> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'type': type,
  };

  factory KbItem.fromJson(Map<String, String> json) => KbItem(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    type: json['type'] ?? 'text',
  );
}

// Provider
final kbProvider = NotifierProvider<KbNotifier, List<KbItem>>(KbNotifier.new);

class KbNotifier extends Notifier<List<KbItem>> {
  @override
  List<KbItem> build() {
    final storage = ref.read(storageServiceProvider);
    final raw = storage.getKnowledgeBase();
    return raw.map((e) => KbItem.fromJson(e)).toList();
  }

  Future<void> addItem(String title, String content, String type) async {
    final newItem = KbItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      type: type,
    );
    state = [...state, newItem];
    _save();
  }

  Future<void> deleteItem(String id) async {
    state = state.where((e) => e.id != id).toList();
    _save();
  }

  Future<void> _save() async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveKnowledgeBase(state.map((e) => e.toJson()).toList());
  }
}

class KnowledgeBaseScreen extends ConsumerStatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  ConsumerState<KnowledgeBaseScreen> createState() =>
      _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends ConsumerState<KnowledgeBaseScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _searchController = TextEditingController();
  String _type = 'text';
  String _searchQuery = '';

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Knowledge Base Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                DropdownMenuItem(value: 'text', child: Text('Text')),
                DropdownMenuItem(value: 'link', child: Text('Link')),
              ],
              onChanged: (val) => setState(() => _type = val!),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              minLines: _type == 'text' ? 3 : 1,
              maxLines: _type == 'text' ? 5 : 1,
              decoration: InputDecoration(
                labelText: _type == 'text' ? 'Content' : 'URL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty &&
                  _contentController.text.isNotEmpty) {
                ref
                    .read(kbProvider.notifier)
                    .addItem(
                      _titleController.text,
                      _contentController.text,
                      _type,
                    );
                _titleController.clear();
                _contentController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(kbProvider);
    final items = allItems.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.title.toLowerCase().contains(query) ||
          item.content.toLowerCase().contains(query);
    }).toList();

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
                  'Knowledge Base',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Add context for your bot.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(LucideIcons.plus),
              label: const Text("Add Item"),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Search Bar
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search KB articles...',
            prefixIcon: const Icon(LucideIcons.search, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    "No items yet.",
                    style: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          item.type == 'link'
                              ? LucideIcons.link
                              : LucideIcons.fileText,
                          color: AppColors.primaryGreen,
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          item.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            LucideIcons.trash2,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          onPressed: () =>
                              ref.read(kbProvider.notifier).deleteItem(item.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
