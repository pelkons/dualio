import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_card_base.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter/material.dart';

class SemanticItemFeedCard extends StatelessWidget {
  const SemanticItemFeedCard({
    required this.item,
    required this.onTap,
    this.onRetry,
    super.key,
  });

  final SemanticItem item;
  final VoidCallback onTap;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (item.usesImageAnalysisPresentation) {
      return ImageAnalysisFeedCard(item: item, onTap: onTap);
    }

    if (item.usesGenericLinkPresentation) {
      return LinkPreviewFeedCard(item: item, onTap: onTap);
    }

    return switch (item.type) {
      ItemType.article => ArticleFeedCard(item: item, onTap: onTap),
      ItemType.recipe => RecipeFeedCard(item: item, onTap: onTap),
      ItemType.film => FilmFeedCard(item: item, onTap: onTap),
      ItemType.place => PlaceFeedCard(item: item, onTap: onTap),
      ItemType.product => ProductFeedCard(item: item, onTap: onTap),
      ItemType.video => VideoFeedCard(item: item, onTap: onTap),
      ItemType.manual => ManualFeedCard(item: item, onTap: onTap),
      ItemType.note => NoteFeedCard(item: item, onTap: onTap),
      ItemType.unknown => UnknownFeedCard(
        item: item,
        onTap: onTap,
        onRetry: onRetry,
      ),
    };
  }
}

class ImageAnalysisFeedCard extends StatelessWidget {
  const ImageAnalysisFeedCard({
    required this.item,
    required this.onTap,
    super.key,
  });

  final SemanticItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final visibleText = item.parsedContent['visibleText'] as String?;
    final hasSummary = item.searchableSummary.trim().isNotEmpty;
    final hasVisibleText = visibleText != null && visibleText.trim().isNotEmpty;

    return FeedCardFrame(
      onTap: onTap,
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ImageHero(
            url: item.thumbnailUrl,
            height: 178,
            meta: CardMeta(
              icon: Icons.image_rounded,
              label: strings.addFromLibrary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (hasSummary) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    item.searchableSummary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).extension<DualioPalette>()!.muted,
                      fontSize: 14,
                    ),
                  ),
                ] else if (hasVisibleText) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    visibleText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).extension<DualioPalette>()!.muted,
                      fontSize: 14,
                    ),
                  ),
                ],
                _Footer(label: item.createdLabel, withDivider: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LinkPreviewFeedCard extends StatelessWidget {
  const LinkPreviewFeedCard({
    required this.item,
    required this.onTap,
    super.key,
  });
  final SemanticItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final authorName = item.parsedContent['authorName'] as String?;
    final siteName = item.parsedContent['siteName'] as String?;
    final meta = CardMeta(
      icon: Icons.link_rounded,
      label: strings.captureSourceLink,
    );

    if (item.thumbnailUrl != null) {
      return FeedCardFrame(
        onTap: onTap,
        padding: EdgeInsets.zero,
        clip: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ImageHero(url: item.thumbnailUrl, height: 178, meta: meta),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (authorName != null || siteName != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _MutedLine(
                      text: <String>[
                        if (authorName != null) authorName,
                        if (siteName != null) siteName,
                      ].join(' - '),
                    ),
                  ],
                  if (item.searchableSummary.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      item.searchableSummary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).extension<DualioPalette>()!.muted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  _Footer(label: item.createdLabel, withDivider: true),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return FeedCardFrame(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          meta,
          const SizedBox(height: 14),
          Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
          if (authorName != null || siteName != null) ...<Widget>[
            const SizedBox(height: 8),
            _MutedLine(
              text: <String>[
                if (authorName != null) authorName,
                if (siteName != null) siteName,
              ].join(' - '),
            ),
          ],
          if (item.searchableSummary.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              item.searchableSummary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).extension<DualioPalette>()!.muted,
                fontSize: 14,
              ),
            ),
          ],
          _Footer(label: item.createdLabel),
        ],
      ),
    );
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
    final authorName = item.parsedContent['authorName'] as String?;
    final siteName = item.parsedContent['siteName'] as String?;
    final metaLabel = readMinutes == null
        ? strings.articleType
        : '${strings.articleType} - ${strings.minutesRead(readMinutes)}';
    final meta = CardMeta(icon: Icons.article_rounded, label: metaLabel);

    if (item.thumbnailUrl != null) {
      return FeedCardFrame(
        onTap: onTap,
        padding: EdgeInsets.zero,
        clip: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ImageHero(url: item.thumbnailUrl, height: 178, meta: meta),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (authorName != null || siteName != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _MutedLine(
                      text: <String>[
                        if (authorName != null) authorName,
                        if (siteName != null) siteName,
                      ].join(' - '),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    item.searchableSummary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).extension<DualioPalette>()!.muted,
                      fontSize: 14,
                    ),
                  ),
                  _Footer(label: item.createdLabel, withDivider: true),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return FeedCardFrame(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          meta,
          const SizedBox(height: 14),
          Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
          if (authorName != null || siteName != null) ...<Widget>[
            const SizedBox(height: 8),
            _MutedLine(
              text: <String>[
                if (authorName != null) authorName,
                if (siteName != null) siteName,
              ].join(' - '),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            item.searchableSummary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).extension<DualioPalette>()!.muted,
              fontSize: 14,
            ),
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
    final facts = <String>[
      item.parsedContent['prepTime'] as String? ?? '',
      item.parsedContent['cookTime'] as String? ?? '',
      item.parsedContent['difficulty'] as String? ?? '',
      item.parsedContent['servings'] as String? ?? '',
    ].where((value) => value.trim().isNotEmpty).toList(growable: false);

    return FeedCardFrame(
      onTap: onTap,
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ImageHero(
            url: item.thumbnailUrl,
            height: 170,
            meta: CardMeta(
              icon: Icons.restaurant_rounded,
              label: strings.recipeType,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (facts.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  _InlineFacts(facts: facts),
                ] else if (item.searchableSummary.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    item.searchableSummary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).extension<DualioPalette>()!.muted,
                      fontSize: 14,
                    ),
                  ),
                ],
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
            CachedNetworkImage(
              imageUrl: item.thumbnailUrl ?? '',
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: CardMeta(
                icon: Icons.movie_rounded,
                label: strings.filmType,
                inverse: true,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      ...List<Widget>.generate(
                        5,
                        (index) => const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFFFD33D),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.parsedContent['rating']}',
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: Colors.white),
                      ),
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
    return _ImageSummaryCard(
      item: item,
      icon: Icons.place_rounded,
      label: strings.placeType,
      facts: <String>[
        item.parsedContent['venueType']! as String,
        item.parsedContent['hours']! as String,
      ],
      onTap: onTap,
    );
  }
}

class ProductFeedCard extends StatelessWidget {
  const ProductFeedCard({required this.item, required this.onTap, super.key});
  final SemanticItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _ImageSummaryCard(
      item: item,
      icon: Icons.shopping_bag_rounded,
      label: strings.productType,
      facts: <String>[
        item.parsedContent['price']! as String,
        item.parsedContent['store']! as String,
      ],
      onTap: onTap,
    );
  }
}

class VideoFeedCard extends StatelessWidget {
  const VideoFeedCard({required this.item, required this.onTap, super.key});
  final SemanticItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final authorName = item.parsedContent['authorName'] as String?;
    final siteName = item.parsedContent['siteName'] as String?;
    final duration = item.parsedContent['duration'] as String?;
    return _ImageSummaryCard(
      item: item,
      icon: Icons.smart_display_rounded,
      label: strings.videoType,
      facts: <String>[
        if (authorName != null) authorName,
        if (authorName == null && siteName != null) siteName,
        if (duration != null) duration,
      ],
      onTap: onTap,
    );
  }
}

class ManualFeedCard extends StatelessWidget {
  const ManualFeedCard({required this.item, required this.onTap, super.key});
  final SemanticItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final steps = _stringList(item.parsedContent['steps']);
    final source = item.parsedContent['siteName'] as String?;
    final facts = <String>[
      if (steps.isNotEmpty) strings.stepsCount(steps.length),
      if (source != null) source,
    ];

    return FeedCardFrame(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CardMeta(icon: Icons.checklist_rounded, label: strings.manualType),
          const SizedBox(height: 14),
          Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
          if (item.searchableSummary.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              item.searchableSummary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).extension<DualioPalette>()!.muted,
                fontSize: 14,
              ),
            ),
          ],
          if (facts.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _InlineFacts(facts: facts),
          ],
          _Footer(label: item.createdLabel),
        ],
      ),
    );
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
          CardMeta(
            icon: Icons.format_quote_rounded,
            label: strings.highlightType,
          ),
          const SizedBox(height: 18),
          Text(
            '"${item.title}"',
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 29, height: 1.17),
          ),
          if (author != null) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              '- $author',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.muted,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            item.createdLabel,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

List<String> _stringList(Object? value) {
  if (value is! List<Object?>) {
    return const <String>[];
  }
  return value
      .whereType<Object>()
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

class UnknownFeedCard extends StatelessWidget {
  const UnknownFeedCard({
    required this.item,
    required this.onTap,
    this.onRetry,
    super.key,
  });
  final SemanticItem item;
  final VoidCallback onTap;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final isProcessing =
        item.processingStatus == ProcessingStatus.pending ||
        item.processingStatus == ProcessingStatus.processing;
    if (isProcessing) {
      return ProcessingFeedCard(onTap: onTap);
    }

    if (item.thumbnailUrl != null &&
        (item.sourceType == SourceType.photo ||
            item.sourceType == SourceType.screenshot)) {
      return _ImageSummaryCard(
        item: item,
        icon: Icons.image_rounded,
        label: strings.addFromLibrary,
        facts: const <String>[],
        onTap: onTap,
      );
    }

    final isRestrictedSocialLink =
        item.parsedContent['kind'] == 'restricted_social_link';
    final isFailed = item.processingStatus == ProcessingStatus.failed;
    final label = isRestrictedSocialLink
        ? strings.socialLinkType
        : isFailed
        ? strings.processingFailedType
        : strings.needsClarificationType;
    final icon = isRestrictedSocialLink
        ? Icons.link_rounded
        : isFailed
        ? Icons.error_outline_rounded
        : Icons.info_outline_rounded;
    final body = isRestrictedSocialLink
        ? strings.socialLinkLimited
        : item.clarificationQuestion ?? item.searchableSummary;
    return FeedCardFrame(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CardMeta(icon: icon, label: label),
          const SizedBox(height: 12),
          Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.muted,
              fontSize: 14,
            ),
          ),
          if (isFailed && onRetry != null) ...<Widget>[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(strings.retryProcessing),
            ),
          ],
          _Footer(label: item.createdLabel),
        ],
      ),
    );
  }
}

class ProcessingFeedCard extends StatefulWidget {
  const ProcessingFeedCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  State<ProcessingFeedCard> createState() => _ProcessingFeedCardState();
}

class _ProcessingFeedCardState extends State<ProcessingFeedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<DualioPalette>()!;

    return FeedCardFrame(
      onTap: widget.onTap,
      subtle: true,
      child: SizedBox(
        height: 168,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ProcessingLinesPainter(
                      progress: _controller.value,
                      color: palette.outline.withValues(alpha: 0.16),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RotationTransition(
                    turns: _controller,
                    child: Icon(
                      Icons.sync_rounded,
                      size: 30,
                      color: palette.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings.processingType,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
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

class _ProcessingLinesPainter extends CustomPainter {
  const _ProcessingLinesPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final offset = progress * 28;

    for (var x = -size.height; x < size.width + size.height; x += 28) {
      canvas.drawLine(
        Offset(x + offset, size.height),
        Offset(x + size.height * 0.55 + offset, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProcessingLinesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _ImageSummaryCard extends StatelessWidget {
  const _ImageSummaryCard({
    required this.item,
    required this.icon,
    required this.label,
    required this.facts,
    required this.onTap,
  });
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
          _ImageHero(
            url: item.thumbnailUrl,
            height: 138,
            meta: CardMeta(icon: icon, label: label),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                if (facts.isNotEmpty) _InlineFacts(facts: facts),
                _Footer(label: item.createdLabel, withDivider: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedLine extends StatelessWidget {
  const _MutedLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: palette.muted),
    );
  }
}

class _ImageHero extends StatelessWidget {
  const _ImageHero({
    required this.url,
    required this.height,
    required this.meta,
  });
  final String? url;
  final double height;
  final CardMeta meta;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (url != null)
            _FeedImage(url: url!)
          else
            ColoredBox(color: palette.pill),
          Positioned(
            top: 10,
            left: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.66)
                    : Colors.white.withValues(alpha: 0.9),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: CardMeta(
                  icon: meta.icon,
                  label: meta.label,
                  inverse: isDark || meta.inverse,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedImage extends StatelessWidget {
  const _FeedImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (_isLocalPath(url)) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: Theme.of(context).extension<DualioPalette>()!.pill,
        ),
      );
    }
    return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
  }
}

bool _isLocalPath(String value) {
  return value.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value);
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
            Text(
              fact,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: palette.muted),
            ),
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
        if (withDivider)
          Divider(color: palette.outline.withValues(alpha: 0.35), height: 1),
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
