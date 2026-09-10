import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Password hashing utilities.
///
/// IMPORTANT (production note): In the full production deployment,
/// authentication and password hashing happen on the backend server
/// using a slow, salted algorithm (bcrypt/argon2) — see backend/README.
/// This on-device implementation exists so the Flutter app is fully
/// functional standalone (offline-first / guest / local accounts) and
/// NEVER stores plaintext passwords, matching the "never store plaintext
/// passwords" security requirement even in local-only mode.
class SecurityUtils {
  SecurityUtils._();

  static String generateSalt({int length = 16}) {
    final random = Random.secure();
    final values = Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
    return base64UrlEncode(values);
  }

  /// Salted, iterated SHA-256 hash (lightweight PBKDF-style stretching).
  static String hashPassword(String password, String salt) {
    List<int> result = utf8.encode(password + salt);
    // Iterate to increase computational cost (basic key stretching).
    for (var i = 0; i < 12000; i++) {
      result = sha256.convert(result).bytes;
    }
    return base64UrlEncode(result);
  }

  static bool verifyPassword(String password, String salt, String expectedHash) {
    final actual = hashPassword(password, salt);
    return _constantTimeEquals(actual, expectedHash);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  static String generateId() {
    final random = Random.secure();
    final values = List<int>.generate(20, (_) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email.trim());
  }

  static String? passwordStrengthError(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Add at least one uppercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Add at least one number.';
    }
    return null;
  }
}
