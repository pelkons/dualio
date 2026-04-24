import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_shell.dart';
import 'package:dualio/features/shared/placeholder_panel.dart';
import 'package:flutter/material.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return FeedShell(
      child: PlaceholderPanel(
        title: strings.categoriesTitle,
        body: strings.categoriesBody,
      ),
    );
  }
}
