import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import 'api_keys_screen.dart'; // import provider
import 'knowledge_base_screen.dart'; // import provider
import 'admin_layout.dart'; // import provider
import '../../../services/storage/storage_service.dart';

final analyticsProvider = Provider<Map<String, int>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getAnalytics();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers to get real counts
    final apiKeys = ref.watch(apiKeysProvider);
    final kbItems = ref.watch(kbProvider);
    final analytics = ref.watch(analyticsProvider);

    final activeKeys = apiKeys.where((k) => k.isActive).length;
    final totalKeys = apiKeys.length;
    final isBotHealthy = activeKeys > 0;

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
                  'Dashboard',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Overview of your chatbot status.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            // Health Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isBotHealthy
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isBotHealthy ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isBotHealthy ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isBotHealthy ? 'BOT ONLINE' : 'BOT OFFLINE',
                    style: TextStyle(
                      color: isBotHealthy ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _StatCard(
              title: 'API Keys',
              value: '$activeKeys / $totalKeys',
              subtitle: 'Active / Total',
              color: Colors.blue,
              icon: LucideIcons.key,
            ),
            const SizedBox(width: 16),
            _StatCard(
              title: 'Knowledge Base',
              value: '${kbItems.length}',
              subtitle: 'Articles',
              color: Colors.purple,
              icon: LucideIcons.book,
            ),
            const SizedBox(width: 16),
            _StatCard(
              title: 'Analytics: Chats',
              value: '${analytics['total_chats'] ?? 0}',
              subtitle: 'Total Sessions',
              color: Colors.orange,
              icon: LucideIcons.messageCircle,
            ),
            const SizedBox(width: 16),
            _StatCard(
              title: 'Analytics: Messages',
              value: '${analytics['total_messages'] ?? 0}',
              subtitle: 'Total API Calls',
              color: AppColors.primaryGreen,
              icon: LucideIcons.zap,
            ),
          ],
        ),

        const SizedBox(height: 48),

        const Text(
          "Quick Actions",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _ActionButton(
              label: "Add New API Key",
              icon: LucideIcons.plus,
              color: AppColors.primaryGreen,
              onTap: () => ref.read(adminTabProvider.notifier).setTab(1),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActionButton(
                label: "Update Bot Details",
                icon: LucideIcons.edit3,
                color: AppColors.cardColor,
                onTap: () => ref.read(adminTabProvider.notifier).setTab(4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActionButton(
                label: "Get Embed Code",
                icon: LucideIcons.code,
                color: AppColors.primaryGreen,
                onTap: () => _showEmbedSnippet(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActionButton(
                label: "Deployment Guide",
                icon: LucideIcons.globe,
                color: Colors.blueGrey,
                onTap: () => _showDeploymentGuide(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showEmbedSnippet(BuildContext context) {
    final embedCode =
        '''
<!-- ProChat Embed Code -->
<script>
  window.proChatConfig = {
    botId: "prochat_${DateTime.now().millisecondsSinceEpoch}",
    position: "right"
  };
</script>
<iframe 
  src="YOUR_DEPLOYED_URL_HERE" 
  style="position: fixed; bottom: 20px; right: 20px; width: 400px; height: 600px; border: none; z-index: 9999; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.2);"
></iframe>
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Embed in Your Website'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Copy and paste this code into your HTML <body> tag:',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                embedCode,
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Replace YOUR_DEPLOYED_URL_HERE with your hosted bot URL.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: embedCode));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Embed code copied!')),
              );
            },
            child: const Text('Copy & Close'),
          ),
        ],
      ),
    );
  }

  void _showDeploymentGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Row(
          children: [
            Icon(LucideIcons.globe, color: AppColors.primaryGreen),
            SizedBox(width: 12),
            Text('Deploy Your Chat Bot', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your chat bot is ready to go public! Use these methods to deploy it for free:',
                  style: TextStyle(color: AppColors.textGrey),
                ),
                const SizedBox(height: 24),
                _DeploymentStep(
                  title: '1. Build for Web',
                  description: 'Run this command in your terminal:',
                  code: 'flutter build web --release --base-href "/"',
                ),
                const SizedBox(height: 16),
                _DeploymentStep(
                  title: '2. GitHub Pages (Recommended)',
                  description:
                      'Create a repository, upload the contents of "build/web" to the "gh-pages" branch.',
                ),
                const SizedBox(height: 16),
                _DeploymentStep(
                  title: '3. Vercel/Netlify',
                  description:
                      'Simply drag and drop the "build/web" folder to their dashboard.',
                ),
                const SizedBox(height: 24),
                const Text(
                  'Note: Since this app uses Local Storage, your API keys and settings stay in your browser. For a multi-user production app, consider connecting a backend database.',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _DeploymentStep extends StatelessWidget {
  final String title;
  final String description;
  final String? code;

  const _DeploymentStep({
    required this.title,
    required this.description,
    this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(description, style: const TextStyle(color: AppColors.textGrey)),
        if (code != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              code!,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          // border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color == AppColors.primaryGreen
            ? Colors.black
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
