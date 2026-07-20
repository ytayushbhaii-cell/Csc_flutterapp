import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/tools_data.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final histProvider = context.watch<HistoryProvider>();
    final favProvider = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── App Info Card ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withAlpha(200)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.offline_bolt,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppConstants.appName,
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                      Text('v${AppConstants.version}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.wifi_off,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text('100% Offline',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: Colors.white70)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Usage Stats ─────────────────────────────────────────────────
          const _SectionLabel('Usage'),
          Card(
            child: Column(children: [
              _InfoRow(
                icon: Icons.construction_outlined,
                iconColor: const Color(0xFF3B82F6),
                label: 'Total Tools',
                value: '${allTools.length}',
              ),
              _Divider(cs: cs),
              _InfoRow(
                icon: Icons.favorite_border,
                iconColor: const Color(0xFFEC4899),
                label: 'Favorites',
                value: '${favProvider.ids.length}',
              ),
              _Divider(cs: cs),
              _InfoRow(
                icon: Icons.history,
                iconColor: const Color(0xFF10B981),
                label: 'History Entries',
                value: '${histProvider.entries.length}',
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Appearance ──────────────────────────────────────────────────
          const _SectionLabel('Appearance'),
          Card(
            child: Column(children: [
              SwitchListTile(
                secondary: const _IconBox(
                    icon: Icons.dark_mode_outlined,
                    color: Color(0xFF6366F1)),
                title: const Text('Dark Mode'),
                subtitle: Text(themeProvider.isDark ? 'On' : 'Off'),
                value: themeProvider.isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeColor: cs.primary,
              ),
              _Divider(cs: cs),
              ListTile(
                leading: const _IconBox(
                    icon: Icons.palette_outlined, color: Color(0xFF8B5CF6)),
                title: const Text('Theme'),
                subtitle: Text(themeProvider.themeMode == ThemeMode.dark
                    ? 'Dark'
                    : themeProvider.themeMode == ThemeMode.light
                        ? 'Light'
                        : 'System Default'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, themeProvider),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Preferences ─────────────────────────────────────────────────
          const _SectionLabel('Preferences'),
          Card(
            child: Column(children: [
              ListTile(
                leading: const _IconBox(
                    icon: Icons.translate, color: Color(0xFF0891B2)),
                title: const Text('Language'),
                subtitle: Text(
                    settingsProvider.language == 'hi' ? 'हिंदी' : 'English'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, settingsProvider),
              ),
              _Divider(cs: cs),
              ListTile(
                leading: const _IconBox(
                    icon: Icons.print_outlined, color: Color(0xFFD97706)),
                title: const Text('Print Size'),
                subtitle: Text(settingsProvider.printSize),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _showPrintSizeDialog(context, settingsProvider),
              ),
              _Divider(cs: cs),
              ListTile(
                leading: const _IconBox(
                    icon: Icons.folder_outlined, color: Color(0xFF059669)),
                title: const Text('Default Folder'),
                subtitle: const Text('Downloads'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Backup ──────────────────────────────────────────────────────
          const _SectionLabel('Backup'),
          Card(
            child: Column(children: [
              ListTile(
                leading: const _IconBox(
                    icon: Icons.backup_outlined, color: Color(0xFF2563EB)),
                title: const Text('Backup Data'),
                subtitle: const Text('Export favorites & history'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showBackupDialog(context),
              ),
              _Divider(cs: cs),
              ListTile(
                leading: const _IconBox(
                    icon: Icons.restore, color: Color(0xFF7C3AED)),
                title: const Text('Restore Data'),
                subtitle: const Text('Import from backup file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── About ───────────────────────────────────────────────────────
          const _SectionLabel('About'),
          Card(
            child: Column(children: [
              _InfoRow(
                icon: Icons.info_outlined,
                iconColor: cs.primary,
                label: 'App Name',
                value: AppConstants.appName,
              ),
              _Divider(cs: cs),
              _InfoRow(
                icon: Icons.tag,
                iconColor: cs.primary,
                label: 'Version',
                value: AppConstants.version,
              ),
              _Divider(cs: cs),
              const _InfoRow(
                icon: Icons.android,
                iconColor: Color(0xFF3DDC84),
                label: 'Platform',
                value: 'Android',
              ),
              _Divider(cs: cs),
              ListTile(
                leading: const _IconBox(
                    icon: Icons.security, color: Color(0xFF059669)),
                title: const Text('Privacy Policy'),
                subtitle: const Text('All data stays on your device'),
                trailing: Icon(Icons.check_circle,
                    color: Colors.green.shade600, size: 20),
              ),
            ]),
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              '${AppConstants.appName} v${AppConstants.version}\nMade for CSC Centers',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurface.withAlpha(100)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider provider) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choose Theme'),
        children: [
          _ThemeOption(
              label: 'Light',
              icon: Icons.light_mode_outlined,
              selected: provider.themeMode == ThemeMode.light,
              onTap: () {
                provider.setThemeMode(ThemeMode.light);
                Navigator.of(ctx).pop();
              }),
          _ThemeOption(
              label: 'Dark',
              icon: Icons.dark_mode_outlined,
              selected: provider.themeMode == ThemeMode.dark,
              onTap: () {
                provider.setThemeMode(ThemeMode.dark);
                Navigator.of(ctx).pop();
              }),
          _ThemeOption(
              label: 'System Default',
              icon: Icons.brightness_auto_outlined,
              selected: provider.themeMode == ThemeMode.system,
              onTap: () {
                provider.setThemeMode(ThemeMode.system);
                Navigator.of(ctx).pop();
              }),
        ],
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, SettingsProvider provider) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Language'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              provider.setLanguage('en');
              Navigator.of(ctx).pop();
            },
            child: Row(children: [
              const Text('🇬🇧', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              const Text('English'),
              const Spacer(),
              if (provider.language == 'en')
                Icon(Icons.check,
                    color: Theme.of(context).colorScheme.primary, size: 18),
            ]),
          ),
          SimpleDialogOption(
            onPressed: () {
              provider.setLanguage('hi');
              Navigator.of(ctx).pop();
            },
            child: Row(children: [
              const Text('🇮🇳', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              const Text('हिंदी'),
              const Spacer(),
              if (provider.language == 'hi')
                Icon(Icons.check,
                    color: Theme.of(context).colorScheme.primary, size: 18),
            ]),
          ),
        ],
      ),
    );
  }

  void _showPrintSizeDialog(
      BuildContext context, SettingsProvider provider) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Print Size'),
        children: ['A4', 'Letter', 'Legal'].map((size) {
          return SimpleDialogOption(
            onPressed: () {
              provider.setPrintSize(size);
              Navigator.of(ctx).pop();
            },
            child: Row(children: [
              const Icon(Icons.print_outlined, size: 20),
              const SizedBox(width: 12),
              Text(size),
              const Spacer(),
              if (provider.printSize == size)
                Icon(Icons.check,
                    color: Theme.of(context).colorScheme.primary, size: 18),
            ]),
          );
        }).toList(),
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup Data'),
        content: const Text(
            'Backup export will be available in a future update. Your data is safely stored on this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK')),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              )),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: cs.outline.withAlpha(60));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _IconBox(icon: icon, color: iconColor),
      title: Text(label),
      trailing: Text(value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                fontWeight: FontWeight.w500,
              )),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      );
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SimpleDialogOption(
      onPressed: onTap,
      child: Row(children: [
        Icon(icon, color: selected ? cs.primary : null),
        const SizedBox(width: 12),
        Text(label),
        const Spacer(),
        if (selected) Icon(Icons.check, color: cs.primary, size: 18),
      ]),
    );
  }
}
