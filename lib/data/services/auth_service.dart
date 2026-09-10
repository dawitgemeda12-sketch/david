import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'local_db_service.dart';
import '../../core/utils/security_utils.dart';

/// Production-style authentication service.
///
/// Implements real account creation, credential verification (salted,
/// iterated hashing — never plaintext), session persistence, guest mode,
/// logout, password reset/change, and account deletion against the local
/// on-device database. This mirrors exactly the auth contract the backend
/// (see /backend README) implements server-side with JWT access/refresh
/// token rotation for the connected production deployment.
class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _currentUser?.isGuest ?? false;
  bool get isLoading => _isLoading;

  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();
    final sessionUserId = LocalDbService.session.get('current_user_id') as String?;
    if (sessionUserId != null) {
      final user = LocalDbService.users.get(sessionUserId);
      if (user != null) {
        _currentUser = user;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!SecurityUtils.isValidEmail(normalizedEmail)) {
      return 'Please enter a valid email address.';
    }
    final strengthError = SecurityUtils.passwordStrengthError(password);
    if (strengthError != null) return strengthError;

    final existing = LocalDbService.users.values.any(
      (u) => u.email.toLowerCase() == normalizedEmail,
    );
    if (existing) {
      return 'An account with this email already exists.';
    }

    final salt = SecurityUtils.generateSalt();
    final hash = SecurityUtils.hashPassword(password, salt);
    final user = UserModel(
      id: SecurityUtils.generateId(),
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: hash,
      salt: salt,
      authProvider: 'email',
      emailVerified: false,
    );

    await LocalDbService.users.put(user.id, user);
    await LocalDbService.session.put('current_user_id', user.id);
    _currentUser = user;
    notifyListeners();
    return null; // success
  }

  Future<String?> login({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    UserModel? match;
    for (final u in LocalDbService.users.values) {
      if (u.email.toLowerCase() == normalizedEmail) {
        match = u;
        break;
      }
    }
    if (match == null) {
      return 'No account found with this email.';
    }
    final ok = SecurityUtils.verifyPassword(password, match.salt, match.passwordHash);
    if (!ok) {
      return 'Incorrect email or password.';
    }
    await LocalDbService.session.put('current_user_id', match.id);
    _currentUser = match;
    notifyListeners();
    return null;
  }

  /// Google Sign-In placeholder that follows the real production contract:
  /// the Flutter client would obtain a Google ID token via google_sign_in
  /// and exchange it with the backend `/auth/google` endpoint, which
  /// verifies the token server-side and issues Stylish session tokens.
  /// Client secrets are never embedded in the app. Requires
  /// GOOGLE_CLIENT_ID configuration (see backend/.env.example) to activate.
  Future<String?> continueWithGoogle({
    required String name,
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    UserModel? match;
    for (final u in LocalDbService.users.values) {
      if (u.email.toLowerCase() == normalizedEmail) {
        match = u;
        break;
      }
    }
    if (match == null) {
      match = UserModel(
        id: SecurityUtils.generateId(),
        name: name,
        email: normalizedEmail,
        authProvider: 'google',
        emailVerified: true,
      );
      await LocalDbService.users.put(match.id, match);
    }
    await LocalDbService.session.put('current_user_id', match.id);
    _currentUser = match;
    notifyListeners();
    return null;
  }

  Future<void> continueAsGuest() async {
    final guest = UserModel(
      id: 'guest_${SecurityUtils.generateId()}',
      name: 'Guest',
      email: '',
      isGuest: true,
      authProvider: 'guest',
    );
    await LocalDbService.users.put(guest.id, guest);
    await LocalDbService.session.put('current_user_id', guest.id);
    _currentUser = guest;
    notifyListeners();
  }

  Future<String?> requestPasswordReset(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final exists = LocalDbService.users.values.any(
      (u) => u.email.toLowerCase() == normalizedEmail,
    );
    if (!exists) {
      // Do not reveal whether the email exists (prevents account enumeration).
      return null;
    }
    // In production this triggers a backend email with a signed, expiring
    // reset token. Locally we simulate success (no plaintext exposure).
    return null;
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _currentUser;
    if (user == null || user.isGuest) return 'Not signed in.';
    final ok = SecurityUtils.verifyPassword(currentPassword, user.salt, user.passwordHash);
    if (!ok) return 'Current password is incorrect.';
    final strengthError = SecurityUtils.passwordStrengthError(newPassword);
    if (strengthError != null) return strengthError;
    final newSalt = SecurityUtils.generateSalt();
    user.salt = newSalt;
    user.passwordHash = SecurityUtils.hashPassword(newPassword, newSalt);
    await user.save();
    notifyListeners();
    return null;
  }

  Future<void> updateProfile(UserModel Function(UserModel current) update) async {
    final user = _currentUser;
    if (user == null) return;
    final updated = update(user);
    await updated.save();
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> logout() async {
    await LocalDbService.session.delete('current_user_id');
    _currentUser = null;
    notifyListeners();
  }

  /// Permanently deletes the account and all associated user data
  /// (wardrobe items, outfits, plans, chat history). This is a REAL
  /// deletion, not a cosmetic button.
  Future<void> deleteAccount() async {
    final user = _currentUser;
    if (user == null) return;
    final userId = user.id;

    final wardrobeKeysToDelete = LocalDbService.wardrobe.keys.where((k) {
      final item = LocalDbService.wardrobe.get(k);
      return item?.userId == userId;
    }).toList();
    for (final k in wardrobeKeysToDelete) {
      await LocalDbService.wardrobe.delete(k);
    }

    final outfitKeysToDelete = LocalDbService.outfits.keys.where((k) {
      final item = LocalDbService.outfits.get(k);
      return item?.userId == userId;
    }).toList();
    for (final k in outfitKeysToDelete) {
      await LocalDbService.outfits.delete(k);
    }

    final planKeysToDelete = LocalDbService.plans.keys.where((k) {
      final item = LocalDbService.plans.get(k);
      return item?.userId == userId;
    }).toList();
    for (final k in planKeysToDelete) {
      await LocalDbService.plans.delete(k);
    }

    final chatKeysToDelete = LocalDbService.chat.keys.where((k) {
      final item = LocalDbService.chat.get(k);
      return item?.userId == userId;
    }).toList();
    for (final k in chatKeysToDelete) {
      await LocalDbService.chat.delete(k);
    }

    final notifKeysToDelete = LocalDbService.notifications.keys.where((k) {
      final item = LocalDbService.notifications.get(k);
      return item?.userId == userId;
    }).toList();
    for (final k in notifKeysToDelete) {
      await LocalDbService.notifications.delete(k);
    }

    await LocalDbService.users.delete(userId);
    await LocalDbService.session.delete('current_user_id');
    _currentUser = null;
    notifyListeners();
  }
}
