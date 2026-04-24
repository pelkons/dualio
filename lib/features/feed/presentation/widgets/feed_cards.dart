import 'package:cached_network_image/cached_network_image.dart';
import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_card_base.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter/material.dart';

class SemanticItemFeedCard extends StatelessWidget {
  const SemanticItemFeedCard({required this.item, required this.onTap, super.key});

  final SemanticItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return switch (item.type) {
      ItemType.article => ArticleFeedCard(item: item, onTap: onTap),
      ItemType.recipe => RecipeFeedCard(item: item, onTap: onTap),
      ItemType.film => FilmFeedCard(item: item, onTap: onTap),
      ItemType.place => PlaceFeedCard(item: item, onTap: onTap),
      ItemType.product => ProductFeedCard(item: item, onTap: onTap),
      ItemType.video => VideoFeedCard(item: item, onTap: onTap),
      ItemType.note => NoteFeedCard(item: item, onTap: onTap),
      ItemType.unknown => UnknownFeedCard(item: item, onTap: onTap),
    };
  }
}

class ArticleFeedCard extends StatelessWidget {
  const ArticleFeedCard({required this.item, required this.onTap, super.key});
  final SemanticItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final readMinutes = item.parsedContent['readMinutes'] as int?;
    final metaLabel = readMinutes == null ? strings.articleType : '${strings.articleType} - ${strings.minutesRead(readMinutes)}';
    return FeedCardFrame(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CardMeta(icon: Icons.article_rounded, label: metaLabel),
          const SizedBox(height: 14),
          Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(
            item.searchableSummary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).extension<DualioPalette>()!.muted, fontSize: 14),
          ),
          _Footer(label: item.createdLabel),
        ],
      ),
    );
  }
}

class RecipeFeedCard extends StatelessWidget {
  const RecipeFeedCard({required this.item, required this.onTap, super.key});
  final SemanticItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return FeedCardFrame(
      onTap: onTap,
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ImageHero(url: item.thumbnailUrl, height: 170, meta: CardMeta(icon: Icons.restaurant_rounded, label: strings.recipeType)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                _InlineFacts(facts: <String>[item.parsedContent['prepTime']! as String, item.parsedContent['difficulty']! as String]),
                _Footer(label: item.createdLabel, withDivider: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FilmFeedCard extends StatelessWidget {
  const FilmFeedCard({required this.item, required this.onTap, super.key});
  final SemanticItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return FeedCardFrame(
      onTap: onTap,
      padding: EdgeInsets.zero,
      clip: true,
      child: AspectRatio(
        aspectRatio: 0.72,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CachedNetworkImage(imageUrl: item.thumbnailUrl ?? '', fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.black.withValues(alpha: 0.12), Colors.black.withValues(alpha: 0.85)],
                ),
              ),
            ),
            Positioned(top: 12, left: 12, child: CardMeta(icon: Icons.movie_rounded, label: strings.filmType, inverse: true)),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      ...List<Widget>.generate(5, (index) => const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFD33D))),
                      const SizedBox(width: 6),
                      Text('${item.parsedContent['rating']}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceFeedCard extends StatelessWidget {
  const PlaceFeedCard({required this.item, required this.onTap, super.key});
  final SemanticItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _ImageSummaryCard(item: item, icon: Icons.place_rounded, label: strings.placeType, facts: <String>[
      item.parsedContent['venueType']! as String,
      item.parsedContent['hours']! as String,
    ], onTap: onTap);
  }
}

class ProductFeedCard extends StatelessWidget {
  const ProductFeedCard({required this.item, required this.onTap, super.key});
  final SemanticItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _ImageSummaryCard(item: item, icon: Icons.shopping_bag_rounded, label: strings.productType, facts: <String>[
      item.parsedContent['price']! as String,
      item.parsedContent['store']! as String,
    ], onTap: onTap);
  }
}

class VideoFeedCard extends StatelessWidget {
  const VideoFeedCard({required this.item, required this.onTap, super.key});
  final SemanticItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _ImageSummaryCard(item: item, icon: Icons.smart_display_rounded, label: strings.videoType, facts: <String>[
      item.parsedContent['channel']! as String,
      item.parsedContent['duration']! as String,
    ], onTap: onTap);
  }
}

class NoteFeedCard extends StatelessWidget {
  const NoteFeedCard({required this.item, required this.onTap, super.key});
  final SemanticItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final author = item.parsedContent['author'] as String?;
    return FeedCardFrame(
      onTap: onTap,
      subtle: true,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CardMeta(icon: Icons.format_quote_rounded, label: strings.highlightType),
          const SizedBox(height: 18),
          Text('"${item.title}"', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 29, height: 1.17)),
          if (author != null) ...<Widget>[
            const SizedBox(height: 14),
            Text('- $author', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.muted, fontSize: 14)),
          ],
          const SizedBox(height: 20),
          Text(item.createdLabel, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class UnknownFeedCard extends StatelessWidget {
  const UnknownFeedCard({required this.item, required this.onTap, super.key});
  final SemanticItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final label = item.processingStatus == ProcessingStatus.pending ? strings.processingType : strings.needsClarificationType;
    final body = item.clarificationQuestion ?? item.searchableSummary;
    return FeedCardFrame(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CardMeta(icon: Icons.help_outline_rounded, label: label),
          const SizedBox(height: 12),
          Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.muted, fontSize: 14)),
          _Footer(label: item.createdLabel),
        ],
      ),
    );
  }
}

class _ImageSummaryCard extends StatelessWidget {
  const _ImageSummaryCard({required this.item, required this.icon, required this.label, required this.facts, required this.onTap});
  final SemanticItem item;
  final IconData icon;
  final String label;
  final List<String> facts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FeedCardFrame(
      onTap: onTap,
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ImageHero(url: item.thumbnailUrl, height: 138, meta: CardMeta(icon: icon, label: label)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                _InlineFacts(facts: facts),
                _Footer(label: item.createdLabel, withDivider: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageHero extends StatelessWidget {
  const _ImageHero({required this.url, required this.height, required this.meta});
  final String? url;
  final double height;
  final Widget meta;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (url != null) CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover) else ColoredBox(color: palette.pill),
          Positioned(
            top: 10,
            left: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: meta),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineFacts extends StatelessWidget {
  const _InlineFacts({required this.facts});
  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: facts.map((fact) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.circle, size: 6, color: palette.muted),
            const SizedBox(width: 6),
            Text(fact, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: palette.muted)),
          ],
        );
      }).toList(),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.label, this.withDivider = false});
  final String label;
  final bool withDivider;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    return Column(
      children: <Widget>[
        SizedBox(height: withDivider ? 14 : 18),
        if (withDivider) Divider(color: palette.outline.withValues(alpha: 0.35), height: 1),
        if (withDivider) const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Icon(Icons.more_horiz_rounded, size: 20, color: palette.muted),
          ],
        ),
      ],
    );
  }
}
