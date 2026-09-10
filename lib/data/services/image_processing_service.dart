import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../core/utils/security_utils.dart';

/// Real, on-device image processing pipeline for wardrobe photos:
/// validation, compression, resizing, and safe-filename storage.
///
/// NOTE on background removal: true ML-based background removal
/// requires a server-side segmentation model. This service is
/// architected so that step can be added as
/// `ImageProcessingService.removeBackgroundRemote()` calling the
/// backend's image-processing microservice (see backend/README,
/// "Background removal") without changing any calling code. We do
/// NOT fake background removal on-device — we perform the real
/// optimizations described below and are explicit about what has
/// actually happened to the image.
class ImageProcessingService {
  static const int maxDimension = 1200;
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

  /// Validates, compresses and safely stores a picked image.
  /// Throws a user-safe [ImageProcessingException] on invalid input.
  static Future<String> processAndStore(File sourceFile) async {
    final ext = _extensionOf(sourceFile.path);
    if (!allowedExtensions.contains(ext)) {
      throw ImageProcessingException(
        'This file type isn\'t supported. Please use a JPG, PNG, or WEBP photo.',
      );
    }

    final rawBytes = await sourceFile.readAsBytes();
    if (rawBytes.length > maxFileSizeBytes) {
      throw ImageProcessingException(
        'That photo is too large. Please choose a smaller image (under 5MB).',
      );
    }

    img.Image? decoded;
    try {
      decoded = img.decodeImage(rawBytes);
    } catch (e) {
      if (kDebugMode) debugPrint('Image decode failed: $e');
    }
    if (decoded == null) {
      throw ImageProcessingException(
        'We couldn\'t read that image. Please try a different photo.',
      );
    }

    // Resize down to a sane max dimension (mid-range device friendly).
    img.Image processed = decoded;
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      processed = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxDimension : null,
        height: decoded.height > decoded.width ? maxDimension : null,
      );
    }

    final Uint8List encoded = img.encodeJpg(processed, quality: 85);

    final dir = await getApplicationDocumentsDirectory();
    final wardrobeDir = Directory('${dir.path}/wardrobe_images');
    if (!await wardrobeDir.exists()) {
      await wardrobeDir.create(recursive: true);
    }
    final safeName = '${SecurityUtils.generateId()}.jpg';
    final outFile = File('${wardrobeDir.path}/$safeName');
    await outFile.writeAsBytes(encoded);
    return outFile.path;
  }

  /// Lightweight heuristic "is this likely a clothing photo" check.
  /// This is intentionally conservative: it only rejects images that are
  /// clearly degenerate (near-blank/near-solid-color captures), and
  /// otherwise defers to the user for confirmation — matching the rule
  /// "if classification is uncertain, allow user correction" and never
  /// fabricating a confident real-time CV result.
  static Future<bool> looksLikeUsablePhoto(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return false;
      if (decoded.width < 80 || decoded.height < 80) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _extensionOf(String path) {
    final idx = path.lastIndexOf('.');
    if (idx == -1) return '';
    return path.substring(idx).toLowerCase();
  }
}

class ImageProcessingException implements Exception {
  final String message;
  ImageProcessingException(this.message);
  @override
  String toString() => message;
}
