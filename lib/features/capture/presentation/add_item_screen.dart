import 'dart:async';
import 'dart:io';

import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/features/capture/application/clipboard_intake_service.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_shell.dart';
import 'package:dualio/features/items/application/semantic_items_controller.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibration/vibration.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  final _clipboard = const ClipboardIntakeService();
  String? _clipboardImagePath;
  bool _showEmptyError = false;
  bool _isPasting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<DualioPalette>()!;

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
            strings.addTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            strings.addBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.muted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 22),
          _PasteClipboardButton(
            label: strings.pasteFromClipboard,
            isBusy: _isPasting,
            onPressed: _isPasting ? null : _pasteFromClipboard,
          ),
          const SizedBox(height: 16),
          if (_clipboardImagePath case final imagePath?)
            _ClipboardImagePreview(
              path: imagePath,
              title: strings.clipboardImageLabel,
              clearLabel: strings.clearClipboardImage,
              errorLabel: strings.clipboardImagePreviewUnavailable,
              onClear: () {
                setState(() {
                  _clipboardImagePath = null;
                  _showEmptyError = false;
                });
              },
            )
          else
            TextField(
              controller: _controller,
              minLines: 5,
              maxLines: 10,
              textInputAction: TextInputAction.newline,
              onChanged: (_) {
                if (_showEmptyError) {
                  setState(() => _showEmptyError = false);
                }
              },
              decoration: InputDecoration(
                labelText: strings.captureInputLabel,
                hintText: strings.captureInputHint,
                errorText: _showEmptyError ? strings.emptyCaptureError : null,
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
            onPressed: _saveCurrentInput,
            icon: const Icon(Icons.all_inbox_rounded),
            label: Text(strings.saveToInbox),
          ),
          const SizedBox(height: 22),
          _CaptureAction(
            icon: Icons.photo_library_rounded,
            title: strings.addFromLibrary,
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(height: 10),
          _CaptureAction(
            icon: Icons.photo_camera_rounded,
            title: strings.addFromCamera,
            onTap: () => _pickImage(ImageSource.camera),
          ),
        ],
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    setState(() {
      _isPasting = true;
      _showEmptyError = false;
    });

    final strings = AppLocalizations.of(context);
    try {
      final payload = await _clipboard.read();
      if (!mounted) {
        return;
      }

      switch (payload.kind) {
        case ClipboardPayloadKind.text:
          final text = payload.text?.trim() ?? '';
          if (text.isEmpty) {
            _showSnackBar(strings.emptyClipboardError);
            return;
          }
          setState(() {
            _clipboardImagePath = null;
            _controller.text = _firstUrlIn(text) ?? text;
          });
        case ClipboardPayloadKind.image:
          final path = payload.path;
          if (path == null || path.trim().isEmpty) {
            _showSnackBar(strings.unsupportedClipboardError);
            return;
          }
          setState(() {
            _clipboardImagePath = path;
            _controller.clear();
          });
          _showSnackBar(strings.clipboardImageReady);
        case ClipboardPayloadKind.empty:
          _showSnackBar(strings.emptyClipboardError);
        case ClipboardPayloadKind.unsupported:
          _showSnackBar(strings.unsupportedClipboardError);
      }
    } on Object {
      if (mounted) {
        _showSnackBar(strings.clipboardPasteFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isPasting = false);
      }
    }
  }

  void _saveCurrentInput() {
    final imagePath = _clipboardImagePath;
    if (imagePath != null) {
      ref
          .read(semanticItemsProvider.notifier)
          .addPendingText(content: imagePath, sourceType: SourceType.photo);
      _notifySuccess();
      context.go('/');
      return;
    }

    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _showEmptyError = true);
      return;
    }

    final sourceType = _sourceTypeForText(value);
    final content = sourceType == SourceType.link ? _firstUrlIn(value)! : value;
    ref
        .read(semanticItemsProvider.notifier)
        .addPendingText(content: content, sourceType: sourceType);
    _notifySuccess();
    context.go('/');
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 2200,
      maxHeight: 2200,
      imageQuality: 90,
    );
    if (image == null || !mounted) {
      return;
    }

    ref
        .read(semanticItemsProvider.notifier)
        .addPendingText(content: image.path, sourceType: SourceType.photo);
    _notifySuccess();
    if (mounted) {
      context.go('/');
    }
  }

  void _notifySuccess() {
    unawaited(Vibration.vibrate(duration: 30));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  SourceType _sourceTypeForText(String value) {
    return _firstUrlIn(value) == null ? SourceType.text : SourceType.link;
  }

  static final _urlPattern = RegExp(r'https?://\S+', caseSensitive: false);

  static final _trailingPunctuation = RegExp(r'[.,;:)\]}>]+$');

  String? _firstUrlIn(String value) {
    final match = _urlPattern.firstMatch(value);
    if (match == null) {
      return null;
    }
    return match.group(0)!.replaceAll(_trailingPunctuation, '');
  }
}

class _PasteClipboardButton extends StatelessWidget {
  const _PasteClipboardButton({
    required this.label,
    required this.isBusy,
    required this.onPressed,
  });

  final String label;
  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: isBusy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.content_paste_rounded),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        side: BorderSide(color: palette.outline.withValues(alpha: 0.55)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
        ),
        textStyle: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _ClipboardImagePreview extends StatelessWidget {
  const _ClipboardImagePreview({
    required this.path,
    required this.title,
    required this.clearLabel,
    required this.errorLabel,
    required this.onClear,
  });

  final String path;
  final String title;
  final String clearLabel;
  final String errorLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.outline.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 8),
            child: Row(
              children: <Widget>[
                const Icon(Icons.image_rounded, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: clearLabel,
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Image.file(
            File(path),
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    errorLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: palette.muted),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CaptureAction extends StatelessWidget {
  const _CaptureAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;

    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: palette.outline.withValues(alpha: 0.45)),
            borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
