import 'package:cached_network_image/cached_network_image.dart';
import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_shell.dart';
import 'package:dualio/features/items/application/semantic_items_controller.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteItems = ref.watch(visibleSemanticItemsProvider).valueOrNull;
    final List<SemanticItem> items = remoteItems ?? ref.watch(semanticItemsProvider);
    final item = items.firstWhere((candidate) => candidate.id == itemId, orElse: () => items.first);
    return FeedShell(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(DualioTheme.mobileMargin, 24, DualioTheme.mobileMargin, 120),
        children: <Widget>[
          switch (item.type) {
            ItemType.recipe => RecipeDetail(item: item),
            ItemType.film => FilmDetail(item: item),
            ItemType.place => PlaceDetail(item: item),
            ItemType.article => ArticleDetail(item: item),
            ItemType.product => ProductDetail(item: item),
            ItemType.video => VideoDetail(item: item),
            ItemType.note => NoteDetail(item: item),
            ItemType.unknown => UnknownDetail(item: item),
          },
        ],
      ),
    );
  }
}

class RecipeDetail extends StatelessWidget {
  const RecipeDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _DetailCard(
      children: <Widget>[
        _HeroImage(url: item.thumbnailUrl),
        _Title(item.title),
        _Section(title: strings.ingredients, children: (item.parsedContent['ingredients']! as List<String>).map((text) => CheckboxListTile(value: false, onChanged: (_) {}, title: Text(text))).toList()),
        _Section(title: strings.steps, children: (item.parsedContent['steps']! as List<String>).indexed.map((entry) => ListTile(leading: Text('${entry.$1 + 1}'), title: Text(entry.$2))).toList()),
        _SourceLink(label: strings.sourceLink),
      ],
    );
  }
}

class FilmDetail extends StatelessWidget {
  const FilmDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _DetailCard(children: <Widget>[
      _HeroImage(url: item.thumbnailUrl, aspectRatio: 2 / 3),
      _Title('${item.title} (${item.parsedContent['year']})'),
      _Muted('${strings.directedBy(item.parsedContent['director']! as String)} - ${item.parsedContent['rating']} / 5'),
      _Muted(item.parsedContent['synopsis']! as String),
      _Section(title: strings.cast, children: (item.parsedContent['cast']! as List<String>).map((name) => ListTile(title: Text(name))).toList()),
      _Section(title: strings.whereToWatch, children: <Widget>[ListTile(title: Text(strings.streamingLinksPlaceholder))]),
    ]);
  }
}

class PlaceDetail extends StatelessWidget {
  const PlaceDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _DetailCard(children: <Widget>[
      _MapPlaceholder(),
      _Title(item.title),
      _Muted(item.parsedContent['address']! as String),
      _Muted('${item.parsedContent['venueType']} - ${strings.hours}: ${item.parsedContent['hours']}'),
      _Section(title: strings.notes, children: <Widget>[ListTile(title: Text(item.parsedContent['notes']! as String))]),
      _SourceLink(label: strings.sourceLink),
    ]);
  }
}

class ArticleDetail extends StatelessWidget {
  const ArticleDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final author = item.parsedContent['author'] as String?;
    final siteName = item.parsedContent['siteName'] as String?;
    final readMinutes = item.parsedContent['readMinutes'] as int?;
    final body = (item.parsedContent['body'] as String?) ?? item.searchableSummary;
    final meta = <String>[
      if (author != null) author,
      if (siteName != null) siteName,
      if (readMinutes != null) strings.minutesRead(readMinutes),
    ].join(' - ');

    return _DetailCard(children: <Widget>[
      if (item.thumbnailUrl != null) _HeroImage(url: item.thumbnailUrl),
      _Title(item.title),
      if (meta.isNotEmpty) _Muted(meta),
      Text(body, style: Theme.of(context).textTheme.bodyMedium),
      _SourceLink(label: strings.sourceLink),
    ]);
  }
}

class ProductDetail extends StatelessWidget {
  const ProductDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _DetailCard(children: <Widget>[
      _HeroImage(url: item.thumbnailUrl),
      _Title(item.title),
      _Muted('${item.parsedContent['price']} - ${item.parsedContent['store']}'),
      _Section(title: strings.keySpecs, children: (item.parsedContent['specs']! as List<String>).map((spec) => ListTile(title: Text(spec))).toList()),
      _SourceLink(label: strings.sourceLink),
    ]);
  }
}

class VideoDetail extends StatelessWidget {
  const VideoDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _DetailCard(children: <Widget>[
      _HeroImage(url: item.thumbnailUrl),
      _Title(item.title),
      _Muted('${item.parsedContent['channel']} - ${item.parsedContent['duration']}'),
      ListTile(leading: const Icon(Icons.play_circle_rounded), title: Text(strings.playableLinkPlaceholder)),
    ]);
  }
}

class NoteDetail extends StatelessWidget {
  const NoteDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final author = item.parsedContent['author'] as String?;
    return _DetailCard(children: <Widget>[
      Text('"${item.title}"', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 30)),
      if (author != null) _Muted('- $author') else _Muted(item.searchableSummary),
    ]);
  }
}

class UnknownDetail extends StatelessWidget {
  const UnknownDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(children: <Widget>[
      _Title(item.title),
      _Muted((item.parsedContent['rawText'] as String?) ?? item.searchableSummary),
      if (item.clarificationQuestion != null) _Muted(item.clarificationQuestion!),
    ]);
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(color: palette.card, borderRadius: BorderRadius.circular(DualioTheme.cardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url, this.aspectRatio = 16 / 10});
  final String? url;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DualioTheme.innerRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: url == null ? const ColoredBox(color: Color(0xFFE5E2E1)) : CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DualioTheme.innerRadius),
      child: const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(color: Color(0xFFE5E2E1), child: Center(child: Icon(Icons.map_rounded, size: 36))),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(top: 18, bottom: 10), child: Text(text, style: Theme.of(context).textTheme.headlineMedium));
  }
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).extension<DualioPalette>()!.muted)),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(title, style: Theme.of(context).textTheme.titleLarge), ...children]),
    );
  }
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(onPressed: () {}, icon: const Icon(Icons.open_in_new_rounded), label: Text(label));
  }
}
