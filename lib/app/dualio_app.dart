import 'package:dualio/core/router/app_router.dart';
import 'package:dualio/core/settings/app_settings_controller.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/features/share_intake/application/share_intake_controller.dart';
import 'package:dualio/features/share_intake/presentation/share_intake_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DualioApp extends ConsumerWidget {
  const DualioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = createRouter();
    final settings = ref.watch(appSettingsProvider);

    return ShareIntakeListener(
      onDraft: (draft) {
        ref.read(pendingShareDraftProvider.notifier).state = draft;
        router.go('/share-confirm');
      },
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Dualio',
        theme: DualioTheme.light(),
        darkTheme: DualioTheme.dark(),
        themeMode: settings.themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }
}
