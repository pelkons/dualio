import 'dart:async';

import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
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
  SourceType _sourceType = SourceType.text;
  bool _showEmptyError = false;

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
        padding: const EdgeInsets.fromLTRB(DualioTheme.mobileMargin, 24, DualioTheme.mobileMargin, 128),
        children: <Widget>[
          Text(strings.addTitle, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(strings.addBody, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.muted, fontSize: 14)),
          const SizedBox(height: 22),
          SegmentedButton<SourceType>(
            segments: <ButtonSegment<SourceType>>[
              ButtonSegment<SourceType>(
                value: SourceType.text,
                icon: const Icon(Icons.notes_rounded),
                label: Text(strings.captureSourceText),
              ),
              ButtonSegment<SourceType>(
                value: SourceType.link,
                icon: const Icon(Icons.link_rounded),
                label: Text(strings.captureSourceLink),
              ),
            ],
            selected: <SourceType>{_sourceType},
            onSelectionChanged: (selection) => setState(() => _sourceType = selection.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 5,
            maxLines: 10,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: strings.captureInputLabel,
              hintText: strings.captureInputHint,
              errorText: _showEmptyError ? strings.emptyCaptureError : null,
              filled: true,
              fillColor: palette.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(DualioTheme.cardRadius)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
                borderSide: BorderSide(color: palette.outline.withValues(alpha: 0.45)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saveTypedInput,
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

  void _saveTypedInput() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _showEmptyError = true);
      return;
    }

    ref.read(semanticItemsProvider.notifier).addPendingText(
          content: value,
          sourceType: _sourceType,
        );
    _notifySuccess();
    context.go('/');
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null || !mounted) {
      return;
    }

    ref.read(semanticItemsProvider.notifier).addPendingText(
          content: image.name,
          sourceType: SourceType.photo,
        );
    _notifySuccess();
    if (mounted) {
      context.go('/');
    }
  }

  void _notifySuccess() {
    unawaited(Vibration.vibrate(duration: 30));
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
              Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyMedium)),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
