import 'dart:io';
import 'dart:math' as math;

import 'package:dualio/features/items/data/local_image_optimizer.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('optimizes a large image to a smaller bounded JPEG', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'dualio-image-optimizer-',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final source = img.Image(width: 1200, height: 800);
    for (var y = 0; y < source.height; y += 1) {
      for (var x = 0; x < source.width; x += 1) {
        source.setPixelRgb(
          x,
          y,
          (x * 3 + y) % 256,
          (x + y * 5) % 256,
          (x * 7 + y * 11) % 256,
        );
      }
    }
    final sourceFile = File(
      '${tempDir.path}${Platform.pathSeparator}photo.jpg',
    );
    await sourceFile.writeAsBytes(
      img.encodeJpg(source, quality: 100),
      flush: true,
    );

    final optimized = await LocalImageOptimizer(
      outputDirectory: tempDir,
      maxPhotoLongEdge: 600,
      photoJpegQuality: 74,
    ).optimizeForUpload(path: sourceFile.path, sourceType: SourceType.photo);

    expect(optimized, isNotNull);
    expect(optimized!.wasOptimized, isTrue);
    expect(optimized.contentType, 'image/jpeg');
    expect(optimized.uploadFilename, 'photo-dualio.jpg');
    expect(optimized.byteSize, lessThan(optimized.originalByteSize));
    expect(await optimized.file.exists(), isTrue);

    final decoded = img.decodeImage(await optimized.file.readAsBytes());
    expect(decoded, isNotNull);
    expect(math.max(decoded!.width, decoded.height), lessThanOrEqualTo(600));
  });

  test(
    'falls back to the original file when decoding is unsupported',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'dualio-image-optimizer-',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final sourceFile = File(
        '${tempDir.path}${Platform.pathSeparator}photo.heic',
      );
      await sourceFile.writeAsBytes(<int>[1, 2, 3, 4], flush: true);

      final optimized = await LocalImageOptimizer(
        outputDirectory: tempDir,
      ).optimizeForUpload(path: sourceFile.path, sourceType: SourceType.photo);

      expect(optimized, isNotNull);
      expect(optimized!.wasOptimized, isFalse);
      expect(optimized.file.path, sourceFile.path);
      expect(optimized.contentType, 'image/heic');
      expect(optimized.byteSize, 4);
    },
  );
}
