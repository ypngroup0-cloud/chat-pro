import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import '../../../core/constants/app_constants.dart';
import '../../../services/storage/storage_service.dart';

// Provider
final botSettingsProvider =
    NotifierProvider<BotSettingsNotifier, Map<String, String>>(
      BotSettingsNotifier.new,
    );

class BotSettingsNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    final storage = ref.read(storageServiceProvider);
    return storage.getBotSettings();
  }

  Future<void> updateSetting(String key, String value) async {
    final newSettings = {...state, key: value};
    state = newSettings;
    await ref.read(storageServiceProvider).saveBotSettings(newSettings);
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _promptController;
  late TextEditingController _welcomeController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(botSettingsProvider);
    _nameController = TextEditingController(
      text: settings['name'] ?? AppConstants.defaultBotName,
    );
    _promptController = TextEditingController(
      text:
          settings['system_prompt'] ??
          'You are a helpful customer service assistant.',
    );
    _welcomeController = TextEditingController(
      text: settings['welcome_message'] ?? AppConstants.defaultWelcomeMessage,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bot Settings',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure your chatbot persona.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          _buildSection('General Information', [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Bot Name'),
              onChanged: (val) => ref
                  .read(botSettingsProvider.notifier)
                  .updateSetting('name', val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _welcomeController,
              decoration: const InputDecoration(
                labelText: 'Welcome Message',
                hintText: 'e.g. Hello! How can I help you?',
              ),
              onChanged: (val) => ref
                  .read(botSettingsProvider.notifier)
                  .updateSetting('welcome_message', val),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSection('System Prompt', [
            const Text(
              'This instruction controls how the AI behaves.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText:
                    'e.g. You are a helpful support agent for [Company]...',
                alignLabelWithHint: true,
              ),
              onChanged: (val) => ref
                  .read(botSettingsProvider.notifier)
                  .updateSetting('system_prompt', val),
            ),
          ]),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.cardColor,
                  backgroundImage:
                      (ref.watch(botSettingsProvider)['logo_base64'] != null &&
                          ref
                              .watch(botSettingsProvider)['logo_base64']!
                              .isNotEmpty)
                      ? MemoryImage(
                          base64Decode(
                            ref.read(botSettingsProvider)['logo_base64']!,
                          ),
                        )
                      : null,
                  child:
                      (ref.watch(botSettingsProvider)['logo_base64'] == null ||
                          ref
                              .watch(botSettingsProvider)['logo_base64']!
                              .isEmpty)
                      ? const Icon(Icons.image, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bot Logo (Optional)",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Visible to customers",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: _pickLogo,
                  child: const Text("Upload"),
                ),
                if (ref.watch(botSettingsProvider)['logo_base64'] != null &&
                    ref.watch(botSettingsProvider)['logo_base64']!.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: () => ref
                        .read(botSettingsProvider.notifier)
                        .updateSetting('logo_base64', ''),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _AdminPasswordSection(),
          const SizedBox(height: 24),
          const _DataManagementSection(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200,
      maxHeight: 200,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      await ref
          .read(botSettingsProvider.notifier)
          .updateSetting('logo_base64', base64String);
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _AdminPasswordSection extends ConsumerStatefulWidget {
  const _AdminPasswordSection();

  @override
  ConsumerState<_AdminPasswordSection> createState() =>
      _AdminPasswordSectionState();
}

class _AdminPasswordSectionState extends ConsumerState<_AdminPasswordSection> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Security',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Update your admin access password.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () async {
                  final pass = _controller.text.trim();
                  if (pass.isNotEmpty) {
                    final messenger = ScaffoldMessenger.of(context);
                    await ref
                        .read(storageServiceProvider)
                        .saveAdminPassword(pass);
                    _controller.clear();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Password updated!')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                ),
                child: const Text('Update'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataManagementSection extends ConsumerWidget {
  const _DataManagementSection();

  void _exportConfig(StorageService storage) {
    final data = storage.exportAllData();
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "prochat_config.json")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _importConfig(
    BuildContext context,
    WidgetRef ref,
    StorageService storage,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.bytes != null) {
        final jsonString = utf8.decode(result.files.single.bytes!);
        final data = jsonDecode(jsonString);

        await storage.importAllData(Map<String, dynamic>.from(data));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuration imported! Please reload the app.'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to import: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(storageServiceProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Management',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Backup or restore your entire bot configuration.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  title: "Export Configuration",
                  subtitle: "Download as .json",
                  icon: Icons.download,
                  onTap: () => _exportConfig(storage),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  context,
                  title: "Import Configuration",
                  subtitle: "Upload .json file",
                  icon: Icons.upload_file,
                  onTap: () => _importConfig(context, ref, storage),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
