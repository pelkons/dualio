import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:flutter/material.dart';

class PlaceholderPanel extends StatelessWidget {
  const PlaceholderPanel({required this.title, required this.body, this.icon, super.key});

  final String title;
  final String body;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(DualioTheme.mobileMargin),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
            border: Border.all(color: palette.outline.withValues(alpha: 0.45)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 28),
                  const SizedBox(height: 18),
                ],
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 10),
                Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
