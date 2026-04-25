import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class OptimizedLocalImage {
  const OptimizedLocalImage({
    required this.file,
    required this.originalPath,
    required this.originalFilename,
    required this.uploadFilename,
    required this.contentType,
    required this.byteSize,
    required this.originalByteSize,
    required this.wasOptimized,
    required this.width,
    required this.height,
  });

  final File file;
  final String originalPath;
  final String originalFilename;
  final String uploadFilename;
  final String contentType;
  final int byteSize;
  final int originalByteSize;
  final bool wasOptimized;
  final int? width;
  final int? height;
}

class LocalImageOptimizer {
  const LocalImageOptimizer({
    this.outputDirectory,
    this.maxPhotoLongEdge = 1600,
    this.maxScreenshotLongEdge = 2200,
    this.photoJpegQuality = 82,
    this.screenshotJpegQuality = 88,
    this.maxUploadBytes = defaultMaxUploadBytes,
  });

  static const defaultMaxUploadBytes = 4 * 1024 * 1024;

  final Directory? outputDirectory;
  final int maxPhotoLongEdge;
  final int maxScreenshotLongEdge;
  final int photoJpegQuality;
  final int screenshotJpegQuality;
  final int maxUploadBytes;

  Future<OptimizedLocalImage?> optimizeForUpload({
    required String path,
    required SourceType sourceType,
  }) async {
    final inputFile = File(path);
    if (!await inputFile.exists()) {
      return null;
    }

    final originalBytes = await inputFile.readAsBytes();
    if (originalBytes.isEmpty) {
      return null;
    }

    final originalFilename = _filename(path);
    final profile = _profileFor(sourceType);
    final optimized = await Isolate.run(
      () => _optimizeImageBytes(
        _ImageOptimizationJob(
          bytes: originalBytes,
          maxLongEdge: profile.maxLongEdge,
          jpegQuality: profile.jpegQuality,
          maxUploadBytes: maxUploadBytes,
        ),
      ),
    );

    if (optimized == null) {
      return OptimizedLocalImage(
        file: inputFile,
        originalPath: path,
        originalFilename: originalFilename,
        uploadFilename: originalFilename,
        contentType: _contentTypeForPath(path),
        byteSize: originalBytes.length,
        originalByteSize: originalBytes.length,
        wasOptimized: false,
        width: null,
        height: null,
      );
    }

    final outputDir = outputDirectory ?? await getTemporaryDirectory();
    await outputDir.create(recursive: true);
    final uploadFilename = _optimizedFilename(originalFilename);
    final outputFile = File(
      '${outputDir.path}${Platform.pathSeparator}'
      'dualio-${DateTime.now().microsecondsSinceEpoch}-$uploadFilename',
    );
    await outputFile.writeAsBytes(optimized.bytes, flush: true);

    return OptimizedLocalImage(
      file: outputFile,
      originalPath: path,
      originalFilename: originalFilename,
      uploadFilename: uploadFilename,
      contentType: 'image/jpeg',
      byteSize: optimized.bytes.length,
      originalByteSize: originalBytes.length,
      wasOptimized: true,
      width: optimized.width,
      height: optimized.height,
    );
  }

  _ImageOptimizationProfile _profileFor(SourceType sourceType) {
    if (sourceType == SourceType.screenshot) {
      return _ImageOptimizationProfile(
        maxLongEdge: maxScreenshotLongEdge,
        jpegQuality: screenshotJpegQuality,
      );
    }
    return _ImageOptimizationProfile(
      maxLongEdge: maxPhotoLongEdge,
      jpegQuality: photoJpegQuality,
    );
  }
}

class _ImageOptimizationProfile {
  const _ImageOptimizationProfile({
    required this.maxLongEdge,
    required this.jpegQuality,
  });

  final int maxLongEdge;
  final int jpegQuality;
}

class _ImageOptimizationJob {
  const _ImageOptimizationJob({
    required this.bytes,
    required this.maxLongEdge,
    required this.jpegQuality,
    required this.maxUploadBytes,
  });

  final Uint8List bytes;
  final int maxLongEdge;
  final int jpegQuality;
  final int maxUploadBytes;
}

class _OptimizedImageBytes {
  const _OptimizedImageBytes({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

_OptimizedImageBytes? _optimizeImageBytes(_ImageOptimizationJob job) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(job.bytes);
  } on Object {
    return null;
  }
  if (decoded == null) {
    return null;
  }

  final oriented = img.bakeOrientation(decoded);
  _OptimizedImageBytes? best;
  for (final attempt in _attemptsFor(job)) {
    final resized = _resizeIfNeeded(oriented, attempt.maxLongEdge);
    final encoded = Uint8List.fromList(
      img.encodeJpg(resized, quality: attempt.jpegQuality),
    );
    if (encoded.length >= job.bytes.length) {
      continue;
    }

    final candidate = _OptimizedImageBytes(
      bytes: encoded,
      width: resized.width,
      height: resized.height,
    );
    if (encoded.length <= job.maxUploadBytes) {
      return candidate;
    }
    if (best == null || encoded.length < best.bytes.length) {
      best = candidate;
    }
  }
  return best;
}

List<_OptimizationAttempt> _attemptsFor(_ImageOptimizationJob job) {
  return <_OptimizationAttempt>[
    _OptimizationAttempt(
      maxLongEdge: job.maxLongEdge,
      jpegQuality: job.jpegQuality,
    ),
    _OptimizationAttempt(
      maxLongEdge: (job.maxLongEdge * 0.8).round(),
      jpegQuality: math.max(70, job.jpegQuality - 8),
    ),
    const _OptimizationAttempt(maxLongEdge: 1280, jpegQuality: 72),
  ];
}

class _OptimizationAttempt {
  const _OptimizationAttempt({
    required this.maxLongEdge,
    required this.jpegQuality,
  });

  final int maxLongEdge;
  final int jpegQuality;
}

img.Image _resizeIfNeeded(img.Image image, int maxLongEdge) {
  final longEdge = math.max(image.width, image.height);
  if (longEdge <= maxLongEdge) {
    return image;
  }

  final scale = maxLongEdge / longEdge;
  return img.copyResize(
    image,
    width: (image.width * scale).round(),
    height: (image.height * scale).round(),
    interpolation: img.Interpolation.average,
  );
}

String _filename(String path) {
  return path.split(RegExp(r'[/\\]')).last.trim();
}

String _optimizedFilename(String originalFilename) {
  final base = originalFilename
      .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
      .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final normalizedBase = base.isEmpty ? 'image' : base;
  return '$normalizedBase-dualio.jpg';
}

String _contentTypeForPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lower.endsWith('.heic')) {
    return 'image/heic';
  }
  return 'image/jpeg';
}
