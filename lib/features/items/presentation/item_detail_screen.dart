import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_shell.dart';
import 'package:dualio/features/items/application/semantic_items_controller.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final _personalNoteDraftProvider =
    StateProvider.family<_PersonalNoteDraft?, String>((ref, itemId) => null);
final _generatedContentDraftProvider =
    StateProvider.family<_GeneratedContentDraft?, String>(
      (ref, itemId) => null,
    );
final _checkedStepsProvider = StateProvider.family<Set<int>, String>(
  (ref, itemId) => const <int>{},
);

class _PersonalNoteDraft {
  const _PersonalNoteDraft({required this.text, required this.isEditing});

  final String text;
  final bool isEditing;
}

class _GeneratedContentDraft {
  const _GeneratedContentDraft({
    required this.title,
    required this.ingredientsText,
    required this.stepsText,
    required this.isEditing,
  });

  final String title;
  final String ingredientsText;
  final String stepsText;
  final bool isEditing;
}

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteItems = ref.watch(visibleSemanticItemsProvider).valueOrNull;
    final List<SemanticItem> items =
        remoteItems ?? ref.watch(semanticItemsProvider);
    final item = items.firstWhere(
      (candidate) => candidate.id == itemId,
      orElse: () => items.first,
    );
    return FeedShell(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          DualioTheme.mobileMargin,
          24,
          DualioTheme.mobileMargin,
          120,
        ),
        children: <Widget>[
          if (item.usesImageAnalysisPresentation)
            ImageAnalysisDetail(item: item)
          else if (item.usesGenericLinkPresentation)
            LinkPreviewDetail(item: item)
          else if (item.usesActionStepsPresentation)
            RecipeDetail(item: item)
          else
            switch (item.type) {
              ItemType.recipe => RecipeDetail(item: item),
              ItemType.film => FilmDetail(item: item),
              ItemType.place => PlaceDetail(item: item),
              ItemType.article => ArticleDetail(item: item),
              ItemType.product => ProductDetail(item: item),
              ItemType.video => VideoDetail(item: item),
              ItemType.manual => RecipeDetail(item: item),
              ItemType.note => NoteDetail(item: item),
              ItemType.unknown => UnknownDetail(item: item),
            },
          const SizedBox(height: 14),
          UserNoteSection(item: item),
        ],
      ),
    );
  }
}

class ImageAnalysisDetail extends StatelessWidget {
  const ImageAnalysisDetail({required this.item, super.key});

  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final summary =
        (item.parsedContent['summary'] as String?) ?? item.searchableSummary;
    final visibleText = item.parsedContent['visibleText'] as String?;

    return _DetailCard(
      children: <Widget>[
        _HeroImage(url: item.thumbnailUrl),
        _Title(item.title),
        if (summary.trim().isNotEmpty)
          Text(summary, style: Theme.of(context).textTheme.bodyMedium),
        if (visibleText != null && visibleText.trim().isNotEmpty)
          _Section(
            title: strings.notes,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(visibleText),
              ),
            ],
          ),
      ],
    );
  }
}

class UserNoteSection extends ConsumerStatefulWidget {
  const UserNoteSection({required this.item, super.key});

  final SemanticItem item;

  @override
  ConsumerState<UserNoteSection> createState() => _UserNoteSectionState();
}

class _UserNoteSectionState extends ConsumerState<UserNoteSection> {
  late final TextEditingController _controller;
  String? _optimisticNote;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(_personalNoteDraftProvider(widget.item.id));
    _controller = TextEditingController(text: draft?.text ?? _currentNote);
    _controller.addListener(_syncDraftText);
  }

  @override
  void didUpdateWidget(UserNoteSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.parsedContent['userNote'] !=
        widget.item.parsedContent['userNote']) {
      _optimisticNote = null;
    }
    if (oldWidget.item.parsedContent['userNote'] !=
            widget.item.parsedContent['userNote'] &&
        !(ref.read(_personalNoteDraftProvider(widget.item.id))?.isEditing ??
            false)) {
      _controller.text = _currentNote;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncDraftText);
    _controller.dispose();
    super.dispose();
  }

  String get _currentNote =>
      _optimisticNote ??
      (widget.item.parsedContent['userNote'] as String?) ??
      '';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final isEditing =
        ref.watch(_personalNoteDraftProvider(widget.item.id))?.isEditing ??
        false;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    strings.personalNote,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: strings.editItem,
                  onPressed: _startEditing,
                  icon: const Icon(Icons.edit_rounded),
                ),
              ],
            ),
            if (isEditing) ...<Widget>[
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: strings.personalNoteHint,
                  filled: true,
                  fillColor: palette.pill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      DualioTheme.innerRadius,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: _cancelEditing,
                    child: Text(strings.deleteItemCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saveNote,
                    child: Text(strings.saveChanges),
                  ),
                ],
              ),
            ] else
              Text(
                _currentNote.isEmpty ? strings.personalNoteEmpty : _currentNote,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _currentNote.isEmpty ? palette.muted : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    final note = _controller.text.trim();
    if (mounted) {
      setState(() {
        _optimisticNote = note;
        _controller.text = note;
      });
      ref.read(_personalNoteDraftProvider(widget.item.id).notifier).state =
          null;
    }
    await ref
        .read(semanticItemsProvider.notifier)
        .updateUserNote(widget.item, note);
  }

  void _startEditing() {
    ref.read(_personalNoteDraftProvider(widget.item.id).notifier).state =
        _PersonalNoteDraft(text: _controller.text, isEditing: true);
  }

  void _cancelEditing() {
    _controller.text = _currentNote;
    ref.read(_personalNoteDraftProvider(widget.item.id).notifier).state = null;
  }

  void _syncDraftText() {
    final draft = ref.read(_personalNoteDraftProvider(widget.item.id));
    if (draft == null) {
      return;
    }
    ref.read(_personalNoteDraftProvider(widget.item.id).notifier).state =
        _PersonalNoteDraft(text: _controller.text, isEditing: draft.isEditing);
  }
}

class LinkPreviewDetail extends StatelessWidget {
  const LinkPreviewDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final authorName = item.parsedContent['authorName'] as String?;
    final siteName = item.parsedContent['siteName'] as String?;
    final description =
        (item.parsedContent['description'] as String?) ??
        item.searchableSummary;
    final meta = <String>[
      strings.captureSourceLink,
      if (authorName != null) authorName,
      if (siteName != null) siteName,
    ].join(' - ');

    return _DetailCard(
      children: <Widget>[
        if (item.thumbnailUrl != null) _HeroImage(url: item.thumbnailUrl),
        _Title(item.title),
        _Muted(meta),
        if (description.isNotEmpty)
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        _SourceLink(label: strings.sourceLink, url: item.sourceUrl),
      ],
    );
  }
}

class RecipeDetail extends ConsumerStatefulWidget {
  const RecipeDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  ConsumerState<RecipeDetail> createState() => _RecipeDetailState();
}

class _RecipeDetailState extends ConsumerState<RecipeDetail> {
  late final TextEditingController _titleController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _stepsController;
  String? _optimisticTitle;
  List<String>? _optimisticIngredients;
  List<String>? _optimisticSteps;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(_generatedContentDraftProvider(widget.item.id));
    _titleController = TextEditingController(
      text: draft?.title ?? _currentTitle,
    );
    _ingredientsController = TextEditingController(
      text: draft?.ingredientsText ?? _linesText(_currentIngredients),
    );
    _stepsController = TextEditingController(
      text: draft?.stepsText ?? _linesText(_currentSteps),
    );
    _titleController.addListener(_syncDraftText);
    _ingredientsController.addListener(_syncDraftText);
    _stepsController.addListener(_syncDraftText);
  }

  @override
  void didUpdateWidget(RecipeDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final draft = ref.read(_generatedContentDraftProvider(widget.item.id));
    final isEditing = draft?.isEditing ?? false;
    if (!isEditing &&
        (oldWidget.item.title != widget.item.title ||
            oldWidget.item.parsedContent != widget.item.parsedContent)) {
      _optimisticTitle = null;
      _optimisticIngredients = null;
      _optimisticSteps = null;
      _resetControllers();
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_syncDraftText);
    _ingredientsController.removeListener(_syncDraftText);
    _stepsController.removeListener(_syncDraftText);
    _titleController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  String get _currentTitle => _optimisticTitle ?? widget.item.title;

  List<String> get _currentIngredients =>
      _optimisticIngredients ??
      _stringList(
        widget.item.type == ItemType.recipe
            ? widget.item.parsedContent['ingredients']
            : widget.item.parsedContent['materials'] ??
                  widget.item.parsedContent['requirements'] ??
                  widget.item.parsedContent['tools'] ??
                  widget.item.parsedContent['ingredients'],
      );

  List<String> get _currentSteps =>
      _optimisticSteps ?? _stringList(widget.item.parsedContent['steps']);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isEditing =
        ref.watch(_generatedContentDraftProvider(widget.item.id))?.isEditing ??
        false;
    final checkedSteps = ref.watch(_checkedStepsProvider(widget.item.id));
    final ingredients = _currentIngredients;
    final steps = _currentSteps;

    return _DetailCard(
      children: <Widget>[
        if (widget.item.thumbnailUrl != null ||
            widget.item.type == ItemType.recipe)
          _HeroImage(url: widget.item.thumbnailUrl),
        _EditableTitleHeader(
          title: _currentTitle,
          tooltip: strings.editGeneratedContent,
          onEdit: _startEditing,
        ),
        if (isEditing)
          _GeneratedContentEditor(
            titleController: _titleController,
            ingredientsController: _ingredientsController,
            stepsController: _stepsController,
            supportingItemsLabel: _supportingItemsLabel(strings),
            supportingItemsHint: _supportingItemsHint(strings),
            onCancel: _cancelEditing,
            onSave: _saveGeneratedContent,
          )
        else ...<Widget>[
          if (ingredients.isNotEmpty)
            _Section(
              title: _supportingItemsLabel(strings),
              children: ingredients
                  .map((text) => _IngredientRow(text: text))
                  .toList(),
            ),
          if (steps.isNotEmpty)
            _Section(
              title: strings.steps,
              children: steps.indexed
                  .map(
                    (entry) => _StepCheckboxTile(
                      number: entry.$1 + 1,
                      text: entry.$2,
                      checked: checkedSteps.contains(entry.$1),
                      onChanged: (value) =>
                          _setStepChecked(entry.$1, value ?? false),
                    ),
                  )
                  .toList(),
            ),
          _SourceLink(label: strings.sourceLink, url: widget.item.sourceUrl),
        ],
      ],
    );
  }

  Future<void> _saveGeneratedContent() async {
    final title = _titleController.text.trim();
    final normalizedTitle = title.isEmpty ? widget.item.title : title;
    final ingredients = _linesFromText(_ingredientsController.text);
    final steps = _linesFromText(_stepsController.text);
    final summary = _generatedContentSummary(
      normalizedTitle,
      ingredients,
      steps,
    );

    if (mounted) {
      setState(() {
        _optimisticTitle = normalizedTitle;
        _optimisticIngredients = ingredients;
        _optimisticSteps = steps;
      });
      ref.read(_generatedContentDraftProvider(widget.item.id).notifier).state =
          null;
      final checked = ref.read(_checkedStepsProvider(widget.item.id));
      ref.read(_checkedStepsProvider(widget.item.id).notifier).state = checked
          .where((index) => index < steps.length)
          .toSet();
    }

    await ref
        .read(semanticItemsProvider.notifier)
        .updateGeneratedContent(
          widget.item,
          title: normalizedTitle,
          parsedContentPatch: <String, Object?>{
            _supportingItemsPatchKey: ingredients,
            'steps': steps,
          },
          searchableSummary: summary,
        );
  }

  void _startEditing() {
    ref
        .read(_generatedContentDraftProvider(widget.item.id).notifier)
        .state = _GeneratedContentDraft(
      title: _titleController.text,
      ingredientsText: _ingredientsController.text,
      stepsText: _stepsController.text,
      isEditing: true,
    );
  }

  void _cancelEditing() {
    _resetControllers();
    ref.read(_generatedContentDraftProvider(widget.item.id).notifier).state =
        null;
  }

  void _setStepChecked(int index, bool checked) {
    final current = ref.read(_checkedStepsProvider(widget.item.id));
    ref.read(_checkedStepsProvider(widget.item.id).notifier).state = checked
        ? <int>{...current, index}
        : current.where((value) => value != index).toSet();
  }

  void _resetControllers() {
    _titleController.text = _currentTitle;
    _ingredientsController.text = _linesText(_currentIngredients);
    _stepsController.text = _linesText(_currentSteps);
  }

  void _syncDraftText() {
    final draft = ref.read(_generatedContentDraftProvider(widget.item.id));
    if (draft == null) {
      return;
    }
    ref
        .read(_generatedContentDraftProvider(widget.item.id).notifier)
        .state = _GeneratedContentDraft(
      title: _titleController.text,
      ingredientsText: _ingredientsController.text,
      stepsText: _stepsController.text,
      isEditing: draft.isEditing,
    );
  }

  String get _supportingItemsPatchKey =>
      widget.item.type == ItemType.recipe ? 'ingredients' : 'materials';

  String _supportingItemsLabel(AppLocalizations strings) =>
      widget.item.type == ItemType.recipe
      ? strings.ingredients
      : strings.materials;

  String _supportingItemsHint(AppLocalizations strings) =>
      widget.item.type == ItemType.recipe
      ? strings.ingredientsEditHint
      : strings.materialsEditHint;
}

class _EditableTitleHeader extends StatelessWidget {
  const _EditableTitleHeader({
    required this.title,
    required this.tooltip,
    required this.onEdit,
  });

  final String title;
  final String tooltip;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          IconButton(
            tooltip: tooltip,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
    );
  }
}

class _GeneratedContentEditor extends StatelessWidget {
  const _GeneratedContentEditor({
    required this.titleController,
    required this.ingredientsController,
    required this.stepsController,
    required this.supportingItemsLabel,
    required this.supportingItemsHint,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController titleController;
  final TextEditingController ingredientsController;
  final TextEditingController stepsController;
  final String supportingItemsLabel;
  final String supportingItemsHint;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final borderRadius = BorderRadius.circular(DualioTheme.innerRadius);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: titleController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: strings.generatedTitleLabel,
            filled: true,
            fillColor: palette.pill,
            border: OutlineInputBorder(borderRadius: borderRadius),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ingredientsController,
          minLines: 4,
          maxLines: 10,
          decoration: InputDecoration(
            labelText: supportingItemsLabel,
            hintText: supportingItemsHint,
            filled: true,
            fillColor: palette.pill,
            border: OutlineInputBorder(borderRadius: borderRadius),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: stepsController,
          minLines: 5,
          maxLines: 14,
          decoration: InputDecoration(
            labelText: strings.steps,
            hintText: strings.stepsEditHint,
            filled: true,
            fillColor: palette.pill,
            border: OutlineInputBorder(borderRadius: borderRadius),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton(
              onPressed: onCancel,
              child: Text(strings.deleteItemCancel),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: onSave, child: Text(strings.saveChanges)),
          ],
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 28,
      leading: Icon(Icons.local_dining_rounded, color: palette.muted, size: 20),
      title: Text(text),
    );
  }
}

class _StepCheckboxTile extends StatelessWidget {
  const _StepCheckboxTile({
    required this.number,
    required this.text,
    required this.checked,
    required this.onChanged,
  });

  final int number;
  final String text;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: checked,
      onChanged: onChanged,
      title: Text(
        '$number. $text',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: checked ? palette.muted : null,
          decoration: checked ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}

class FilmDetail extends StatelessWidget {
  const FilmDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _DetailCard(
      children: <Widget>[
        _HeroImage(url: item.thumbnailUrl, aspectRatio: 2 / 3),
        _Title('${item.title} (${item.parsedContent['year']})'),
        _Muted(
          '${strings.directedBy(item.parsedContent['director']! as String)} - ${item.parsedContent['rating']} / 5',
        ),
        _Muted(item.parsedContent['synopsis']! as String),
        _Section(
          title: strings.cast,
          children: _stringList(
            item.parsedContent['cast'],
          ).map((name) => ListTile(title: Text(name))).toList(),
        ),
        _Section(
          title: strings.whereToWatch,
          children: <Widget>[
            ListTile(title: Text(strings.streamingLinksPlaceholder)),
          ],
        ),
      ],
    );
  }
}

class PlaceDetail extends StatelessWidget {
  const PlaceDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _DetailCard(
      children: <Widget>[
        _MapPlaceholder(),
        _Title(item.title),
        _Muted(item.parsedContent['address']! as String),
        _Muted(
          '${item.parsedContent['venueType']} - ${strings.hours}: ${item.parsedContent['hours']}',
        ),
        _Section(
          title: strings.notes,
          children: <Widget>[
            ListTile(title: Text(item.parsedContent['notes']! as String)),
          ],
        ),
        _SourceLink(label: strings.sourceLink, url: item.sourceUrl),
      ],
    );
  }
}

class ArticleDetail extends StatelessWidget {
  const ArticleDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final author = item.parsedContent['author'] as String?;
    final authorName = item.parsedContent['authorName'] as String?;
    final siteName = item.parsedContent['siteName'] as String?;
    final readMinutes = item.parsedContent['readMinutes'] as int?;
    final body =
        (item.parsedContent['body'] as String?) ?? item.searchableSummary;
    final meta = <String>[
      if (authorName != null) authorName else if (author != null) author,
      if (siteName != null) siteName,
      if (readMinutes != null) strings.minutesRead(readMinutes),
    ].join(' - ');

    return _DetailCard(
      children: <Widget>[
        if (item.thumbnailUrl != null) _HeroImage(url: item.thumbnailUrl),
        _Title(item.title),
        if (meta.isNotEmpty) _Muted(meta),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
        _SourceLink(label: strings.sourceLink, url: item.sourceUrl),
      ],
    );
  }
}

class ProductDetail extends StatelessWidget {
  const ProductDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _DetailCard(
      children: <Widget>[
        _HeroImage(url: item.thumbnailUrl),
        _Title(item.title),
        _Muted(
          '${item.parsedContent['price']} - ${item.parsedContent['store']}',
        ),
        _Section(
          title: strings.keySpecs,
          children: _stringList(
            item.parsedContent['specs'],
          ).map((spec) => ListTile(title: Text(spec))).toList(),
        ),
        _SourceLink(label: strings.sourceLink, url: item.sourceUrl),
      ],
    );
  }
}

class VideoDetail extends StatelessWidget {
  const VideoDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final authorName = item.parsedContent['authorName'] as String?;
    final siteName = item.parsedContent['siteName'] as String?;
    final duration = item.parsedContent['duration'] as String?;
    final meta = <String>[
      if (authorName != null) authorName,
      if (siteName != null) siteName,
      if (duration != null) duration,
    ].join(' - ');
    return _DetailCard(
      children: <Widget>[
        _HeroImage(url: item.thumbnailUrl),
        _Title(item.title),
        if (meta.isNotEmpty) _Muted(meta),
        ListTile(
          leading: const Icon(Icons.play_circle_rounded),
          title: Text(strings.playableLinkPlaceholder),
        ),
      ],
    );
  }
}

class NoteDetail extends StatelessWidget {
  const NoteDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final author = item.parsedContent['author'] as String?;
    return _DetailCard(
      children: <Widget>[
        Text(
          '"${item.title}"',
          style: Theme.of(
            context,
          ).textTheme.displayLarge?.copyWith(fontSize: 30),
        ),
        if (author != null)
          _Muted('- $author')
        else
          _Muted(item.searchableSummary),
      ],
    );
  }
}

class UnknownDetail extends StatelessWidget {
  const UnknownDetail({required this.item, super.key});
  final SemanticItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isRestrictedSocialLink =
        item.parsedContent['kind'] == 'restricted_social_link';
    return _DetailCard(
      children: <Widget>[
        if (item.thumbnailUrl != null) _HeroImage(url: item.thumbnailUrl),
        _Title(item.title),
        if (isRestrictedSocialLink ||
            (item.sourceType != SourceType.photo &&
                item.sourceType != SourceType.screenshot))
          _Muted(
            isRestrictedSocialLink
                ? strings.socialLinkLimited
                : (item.parsedContent['rawText'] as String?) ??
                      item.searchableSummary,
          ),
        if (item.clarificationQuestion != null)
          _Muted(item.clarificationQuestion!),
        _SourceLink(label: strings.sourceLink, url: item.sourceUrl),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
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
        child: url == null
            ? const ColoredBox(color: Color(0xFFE5E2E1))
            : Material(
                color: const Color(0xFFE5E2E1),
                child: InkWell(
                  onTap: () => _openImageViewer(context, url!),
                  child: _DetailImage(url: url!),
                ),
              ),
      ),
    );
  }

  void _openImageViewer(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _ImageViewerScreen(imageUrl: imageUrl),
      ),
    );
  }
}

class _ImageViewerScreen extends StatelessWidget {
  const _ImageViewerScreen({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              child: _RawImage(url: imageUrl),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (_isLocalPath(url)) {
      return Image.file(
        File(url),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: Color(0xFFE5E2E1)),
      );
    }
    return CachedNetworkImage(imageUrl: url, fit: BoxFit.contain);
  }
}

class _RawImage extends StatelessWidget {
  const _RawImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (_isLocalPath(url)) {
      return Image.file(
        File(url),
        errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: Color(0xFFE5E2E1)),
      );
    }
    return CachedNetworkImage(imageUrl: url);
  }
}

bool _isLocalPath(String value) {
  return value.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value);
}

class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DualioTheme.innerRadius),
      child: const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Color(0xFFE5E2E1),
          child: Center(child: Icon(Icons.map_rounded, size: 36)),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).extension<DualioPalette>()!.muted,
        ),
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          ...children,
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

String _linesText(List<String> values) {
  return values.join('\n');
}

List<String> _linesFromText(String value) {
  return value
      .split(RegExp(r'\r?\n'))
      .map((line) => line.replaceFirst(RegExp(r'^\s*(?:[-*]|\d+[.)])\s*'), ''))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

String _generatedContentSummary(
  String title,
  List<String> ingredients,
  List<String> steps,
) {
  return <String>[
    title,
    ...ingredients,
    ...steps,
  ].where((part) => part.trim().isNotEmpty).join('\n');
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.label, required this.url});
  final String label;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final sourceUrl = url;
    if (sourceUrl == null || sourceUrl.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return TextButton.icon(
      onPressed: () => _openSource(sourceUrl),
      icon: const Icon(Icons.open_in_new_rounded),
      label: Text(label),
    );
  }

  Future<void> _openSource(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
