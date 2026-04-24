import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/core/settings/app_settings_controller.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final palette = Theme.of(context).extension<DualioPalette>()!;

    return FeedShell(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(DualioTheme.mobileMargin, 24, DualioTheme.mobileMargin, 128),
        children: <Widget>[
          Text(strings.settingsTitle, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(strings.settingsBody, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.muted, fontSize: 14)),
          const SizedBox(height: 22),
          _SettingsSection(
            title: strings.themeSetting,
            child: SegmentedButton<ThemeMode>(
              segments: <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_rounded), label: Text(strings.themeSystem)),
                ButtonSegment<ThemeMode>(value: ThemeMode.light, icon: const Icon(Icons.light_mode_rounded), label: Text(strings.themeLight)),
                ButtonSegment<ThemeMode>(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_rounded), label: Text(strings.themeDark)),
              ],
              selected: <ThemeMode>{settings.themeMode},
              onSelectionChanged: (selection) => ref.read(appSettingsProvider.notifier).setThemeMode(selection.first),
            ),
          ),
          _SettingsTile(
            icon: Icons.person_rounded,
            title: strings.accountSetting,
            subtitle: strings.accountSettingBody,
            onTap: () => context.go('/sign-in'),
          ),
          _SettingsTile(icon: Icons.workspace_premium_rounded, title: strings.subscriptionSetting, subtitle: strings.subscriptionSettingBody),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
        border: Border.all(color: palette.outline.withValues(alpha: 0.45)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
