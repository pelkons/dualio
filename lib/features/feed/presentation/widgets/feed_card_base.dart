import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter/material.dart';

class FeedCardFrame extends StatelessWidget {
  const FeedCardFrame({
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.subtle = false,
    this.clip = false,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets padding;
  final bool subtle;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;

    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: subtle ? palette.subtle : palette.card,
        borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
        border: Border.all(color: palette.outline.withValues(alpha: 0.45)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 30, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
          onTap: onTap,
          child: clip ? ClipRRect(borderRadius: BorderRadius.circular(DualioTheme.cardRadius), child: card) : card,
        ),
      ),
    );
  }
}

class CardMeta extends StatelessWidget {
  const CardMeta({required this.icon, required this.label, this.inverse = false, super.key});

  final IconData icon;
  final String label;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final color = inverse ? Colors.white : palette.muted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 7),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
        ),
      ],
    );
  }
}

IconData itemIcon(ItemType type) {
  return switch (type) {
    ItemType.article => Icons.article_rounded,
    ItemType.recipe => Icons.restaurant_rounded,
    ItemType.film => Icons.movie_rounded,
    ItemType.place => Icons.place_rounded,
    ItemType.product => Icons.shopping_bag_rounded,
    ItemType.video => Icons.smart_display_rounded,
    ItemType.note => Icons.format_quote_rounded,
    ItemType.unknown => Icons.help_outline_rounded,
  };
}
