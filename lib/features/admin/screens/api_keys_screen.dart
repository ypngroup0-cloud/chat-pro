import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/storage/storage_service.dart';
import '../../chat/chat_service.dart';
import '../models/api_key_model.dart';

// Provider for API Keys
final apiKeysProvider = NotifierProvider<ApiKeysNotifier, List<ApiKeyModel>>(
  ApiKeysNotifier.new,
);

class ApiKeysNotifier extends Notifier<List<ApiKeyModel>> {
  @override
  List<ApiKeyModel> build() {
    final storage = ref.read(storageServiceProvider);
    final rawList = storage.getApiKeys();
    return rawList.map((e) => ApiKeyModel.fromJson(e)).toList();
  }

  Future<void> addKey(String provider, String key) async {
    final newKey = ApiKeyModel(key: key, provider: provider);
    state = [...state, newKey];
    _save();
  }

  Future<void> deleteKey(String key) async {
    state = state.where((k) => k.key != key).toList();
    _save();
  }

  Future<void> toggleKeyStatus(String key, bool active) async {
    state = state.map((k) {
      if (k.key == key) {
        return k.copyWith(isActive: active, cooldownUntil: null);
      }
      return k;
    }).toList();
    _save();
  }

  Future<void> _save() async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveApiKeys(state.map((e) => e.toJson()).toList());
  }
}

class ApiKeysScreen extends ConsumerStatefulWidget {
  const ApiKeysScreen({super.key});

  @override
  ConsumerState<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends ConsumerState<ApiKeysScreen> {
  final _keyController = TextEditingController();
  String _selectedProvider = 'gemini';

  final List<String> _providers = ['gemini', 'openai', 'deepseek', 'grok'];
  bool _isTesting = false;

  Future<void> _testKey(ApiKeyModel key) async {
    setState(() => _isTesting = true);
    final service = ref.read(chatServiceProvider);
    final result = await service.testConnection(key);
    setState(() => _isTesting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result
                ? 'Connection Successful!'
                : 'Connection Failed. Please check the key.',
          ),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiKeys = ref.watch(apiKeysProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'API Keys Management',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage your API keys for different providers. The system will automatically rotate keys to ensure uptime.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),

        // Add Key Config
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Key',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Provider Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedProvider,
                        items: _providers
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _selectedProvider = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Input
                  Expanded(
                    child: TextField(
                      controller: _keyController,
                      decoration: const InputDecoration(
                        hintText: 'Paste API Key here...',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add Button
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_keyController.text.isNotEmpty) {
                        ref
                            .read(apiKeysProvider.notifier)
                            .addKey(
                              _selectedProvider,
                              _keyController.text.trim(),
                            );
                        _keyController.clear();
                      }
                    },
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Add Key'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Lists
        Expanded(
          child: ListView.builder(
            itemCount: _providers.length,
            itemBuilder: (context, index) {
              final provider = _providers[index];
              final keysForProvider = apiKeys
                  .where((k) => k.provider == provider)
                  .toList();

              if (keysForProvider.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      provider.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  ...keysForProvider.map(
                    (apiKey) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.key,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  apiKey.key.replaceRange(
                                    0,
                                    apiKey.key.length > 8
                                        ? apiKey.key.length - 4
                                        : 0,
                                    '*' * 8,
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                if (apiKey.usageCount > 0)
                                  Text(
                                    'Used ${apiKey.usageCount} times',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Status Badge
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: apiKey.isEffectivelyActive
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  apiKey.isEffectivelyActive
                                      ? 'Active'
                                      : (apiKey.isActive
                                            ? 'Cooldown'
                                            : 'Disabled'),
                                  style: TextStyle(
                                    color: apiKey.isEffectivelyActive
                                        ? Colors.green
                                        : Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (apiKey.cooldownUntil != null &&
                                  apiKey.cooldownUntil!.isAfter(DateTime.now()))
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Until ${apiKey.cooldownUntil!.hour}:${apiKey.cooldownUntil!.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Test Connection',
                            icon: Icon(
                              _isTesting
                                  ? LucideIcons.loader2
                                  : LucideIcons.play,
                              size: 18,
                              color: Colors.blueAccent,
                            ),
                            onPressed: _isTesting
                                ? null
                                : () => _testKey(apiKey),
                          ),
                          if (!apiKey.isActive || !apiKey.isEffectivelyActive)
                            IconButton(
                              tooltip: 'Re-enable Key',
                              icon: const Icon(
                                LucideIcons.refreshCcw,
                                size: 18,
                                color: AppColors.primaryGreen,
                              ),
                              onPressed: () => ref
                                  .read(apiKeysProvider.notifier)
                                  .toggleKeyStatus(apiKey.key, true),
                            ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => ref
                                .read(apiKeysProvider.notifier)
                                .deleteKey(apiKey.key),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
