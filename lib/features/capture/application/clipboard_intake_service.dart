import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum ClipboardPayloadKind { empty, text, image, unsupported }

class ClipboardPayload {
  const ClipboardPayload._({
    required this.kind,
    this.text,
    this.path,
    this.mimeType,
  });

  const ClipboardPayload.empty() : this._(kind: ClipboardPayloadKind.empty);

  const ClipboardPayload.text(String value)
    : this._(kind: ClipboardPayloadKind.text, text: value);

  const ClipboardPayload.image({required String path, String? mimeType})
    : this._(kind: ClipboardPayloadKind.image, path: path, mimeType: mimeType);

  const ClipboardPayload.unsupported()
    : this._(kind: ClipboardPayloadKind.unsupported);

  final ClipboardPayloadKind kind;
  final String? text;
  final String? path;
  final String? mimeType;
}

class ClipboardIntakeService {
  const ClipboardIntakeService();

  static const MethodChannel _channel = MethodChannel('dualio/clipboard');

  Future<ClipboardPayload> read() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final payload = await _readAndroidClipboard();
        if (payload != null) {
          return payload;
        }
      } on MissingPluginException {
        return _readTextClipboard();
      } on PlatformException {
        return _readTextClipboard();
      }
    }

    return _readTextClipboard();
  }

  Future<ClipboardPayload?> _readAndroidClipboard() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'readClipboard',
    );
    if (result == null) {
      return null;
    }

    final type = result['type'] as String?;
    return switch (type) {
      'empty' => const ClipboardPayload.empty(),
      'text' => _textPayload(result['text']),
      'image' => _imagePayload(result),
      _ => const ClipboardPayload.unsupported(),
    };
  }

  ClipboardPayload _textPayload(Object? value) {
    final text = value is String ? value.trim() : '';
    if (text.isEmpty) {
      return const ClipboardPayload.empty();
    }
    return ClipboardPayload.text(text);
  }

  ClipboardPayload _imagePayload(Map<String, Object?> result) {
    final path = result['path'];
    if (path is! String || path.trim().isEmpty) {
      return const ClipboardPayload.unsupported();
    }
    final mimeType = result['mimeType'];
    return ClipboardPayload.image(
      path: path,
      mimeType: mimeType is String ? mimeType : null,
    );
  }

  Future<ClipboardPayload> _readTextClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      return const ClipboardPayload.empty();
    }
    return ClipboardPayload.text(text);
  }
}
