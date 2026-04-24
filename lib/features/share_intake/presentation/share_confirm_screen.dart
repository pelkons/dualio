import 'dart:async';
import 'dart:io';

import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_shell.dart';
import 'package:dualio/features/items/application/semantic_items_controller.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:dualio/features/share_intake/application/share_intake_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';

class ShareConfirmScreen extends ConsumerStatefulWidget {
  const ShareConfirmScreen({super.key});

  @override
  ConsumerState<ShareConfirmScreen> createState() => _ShareConfirmScreenState();
}

class _ShareConfirmScreenState extends ConsumerState<ShareConfirmScreen> {
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final draft = ref.watch(pendingShareDraftProvider);

    if (draft == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/');
        }
      });
      return const SizedBox.shrink();
    }

    final preview = _SharePreview.fromDraft(draft);

    return FeedShell(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          DualioTheme.mobileMargin,
          24,
          DualioTheme.mobileMargin,
          128,
        ),
        children: <Widget>[
          Text(
            strings.shareConfirmTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            strings.shareConfirmBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.muted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 22),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
              border: Border.all(
                color: palette.outline.withValues(alpha: 0.45),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(preview.icon, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        preview.label(strings),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (preview.imagePath != null) ...<Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        DualioTheme.innerRadius,
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Image.file(
                          File(preview.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(color: palette.pill),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    preview.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (preview.subtitle != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      preview.subtitle!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.muted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            minLines: 3,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: strings.personalNote,
              hintText: strings.personalNoteHint,
              filled: true,
              fillColor: palette.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
                borderSide: BorderSide(
                  color: palette.outline.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isSaving ? null : () => _save(draft),
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.all_inbox_rounded),
            label: Text(strings.saveToInbox),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isSaving
                ? null
                : () {
                    ref.read(pendingShareDraftProvider.notifier).state = null;
                    context.go('/');
                  },
            child: Text(strings.deleteItemCancel),
          ),
        ],
      ),
    );
  }

  Future<void> _save(ShareDraft draft) async {
    setState(() => _isSaving = true);
    ref
        .read(semanticItemsProvider.notifier)
        .addPendingText(
          content: draft.content,
          sourceType: draft.sourceType,
          personalNote: _noteController.text,
        );
    ref.read(pendingShareDraftProvider.notifier).state = null;
    unawaited(Vibration.vibrate(duration: 30));
    if (mounted) {
      context.go('/');
    }
  }
}

class _SharePreview {
  const _SharePreview({
    required this.title,
    required this.icon,
    required this.label,
    this.subtitle,
    this.imagePath,
  });

  final String title;
  final IconData icon;
  final String Function(AppLocalizations strings) label;
  final String? subtitle;
  final String? imagePath;

  factory _SharePreview.fromDraft(ShareDraft draft) {
    if (draft.sourceType == SourceType.link) {
      final uri = Uri.tryParse(draft.content);
      final host = uri?.host.replaceFirst(RegExp(r'^www\.'), '');
      return _SharePreview(
        title: host?.isNotEmpty == true ? host! : draft.content,
        subtitle: draft.content,
        icon: Icons.link_rounded,
        label: (strings) => strings.captureSourceLink,
      );
    }

    if (draft.sourceType == SourceType.photo ||
        draft.sourceType == SourceType.screenshot) {
      final filename = draft.content.split(RegExp(r'[/\\]')).last;
      return _SharePreview(
        title: filename.isNotEmpty ? filename : draft.content,
        imagePath: draft.content,
        icon: Icons.image_rounded,
        label: (strings) => strings.addFromLibrary,
      );
    }

    final compact = draft.content.replaceAll(RegExp(r'\s+'), ' ');
    return _SharePreview(
      title: compact.length <= 80 ? compact : '${compact.substring(0, 77)}...',
      subtitle: draft.content,
      icon: Icons.notes_rounded,
      label: (strings) => strings.captureSourceText,
    );
  }
}
