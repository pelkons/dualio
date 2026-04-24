import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DualioSearchBar extends StatelessWidget {
  const DualioSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<DualioPalette>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(DualioTheme.mobileMargin, 22, DualioTheme.mobileMargin, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => context.push('/search'),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: palette.pill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.outline.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.search_rounded, size: 20, color: palette.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.searchPlaceholder,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.muted, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
