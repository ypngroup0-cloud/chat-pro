import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'api_keys_screen.dart';
import 'knowledge_base_screen.dart';
import 'quick_questions_screen.dart';
import 'package:go_router/go_router.dart';
import 'admin_login_screen.dart';

// State for current admin tab
class AdminTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setTab(int index) => state = index;
}

final adminTabProvider = NotifierProvider<AdminTabNotifier, int>(
  AdminTabNotifier.new,
);

class AdminLayout extends ConsumerWidget {
  const AdminLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(adminTabProvider);

    final List<Widget> screens = [
      const DashboardScreen(),
      const ApiKeysScreen(),
      const KnowledgeBaseScreen(),
      const QuickQuestionsScreen(),
      const SettingsScreen(),
    ];

    final settings = ref.watch(botSettingsProvider);
    final botName = settings['name'] ?? 'Admin';
    final logoBase64 = settings['logo_base64'];

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: AppColors.surfaceDark,
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo / Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryGreen.withOpacity(
                          0.2,
                        ),
                        backgroundImage:
                            (logoBase64 != null && logoBase64.isNotEmpty)
                            ? MemoryImage(base64Decode(logoBase64))
                            : null,
                        child: (logoBase64 == null || logoBase64.isEmpty)
                            ? const Icon(
                                LucideIcons.bot,
                                color: AppColors.primaryGreen,
                                size: 20,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          botName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Navigation Items
                _AdminNavItem(
                  icon: LucideIcons.layoutDashboard,
                  label: 'Dashboard',
                  isSelected: currentTab == 0,
                  onTap: () => ref.read(adminTabProvider.notifier).setTab(0),
                ),
                _AdminNavItem(
                  icon: LucideIcons.key,
                  label: 'API Keys',
                  isSelected: currentTab == 1,
                  onTap: () => ref.read(adminTabProvider.notifier).setTab(1),
                ),
                _AdminNavItem(
                  icon: LucideIcons.book,
                  label: 'Knowledge Base',
                  isSelected: currentTab == 2,
                  onTap: () => ref.read(adminTabProvider.notifier).setTab(2),
                ),
                _AdminNavItem(
                  icon: LucideIcons.helpCircle,
                  label: 'Quick Questions',
                  isSelected: currentTab == 3,
                  onTap: () => ref.read(adminTabProvider.notifier).setTab(3),
                ),
                _AdminNavItem(
                  icon: LucideIcons.settings,
                  label: 'Settings',
                  isSelected: currentTab == 4,
                  onTap: () => ref.read(adminTabProvider.notifier).setTab(4),
                ),
                _AdminNavItem(
                  icon: LucideIcons.logOut,
                  label: 'Logout',
                  isSelected: false,
                  onTap: () {
                    ref.read(adminAuthProvider.notifier).logout();
                    context.go('/admin/login');
                  },
                ),
                const Spacer(),
                // Share URL
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final baseUrl = Uri.base.toString().split('#').first;
                      final customerUrl = "$baseUrl#/";
                      Clipboard.setData(ClipboardData(text: customerUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Customer Chat URL copied!'),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.share2, size: 18),
                    label: const Text("Share Bot"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: screens[currentTab],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(
                  right: BorderSide(color: AppColors.primaryGreen, width: 3),
                )
              : null,
          color: isSelected ? AppColors.primaryGreen.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryGreen : AppColors.textGrey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.textWhite : AppColors.textGrey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
