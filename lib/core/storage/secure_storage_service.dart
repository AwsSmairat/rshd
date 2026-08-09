import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) {
    return _storage.write(key: StorageKeys.authToken, value: token);
  }

  Future<String?> getToken() {
    return _storage.read(key: StorageKeys.authToken);
  }

  Future<void> deleteToken() {
    return _storage.delete(key: StorageKeys.authToken);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveUser(Map<String, dynamic> user) {
    return _storage.write(key: StorageKeys.userJson, value: jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: StorageKeys.userJson);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  Future<void> clearAll() async {
    await _storage.delete(key: StorageKeys.authToken);
    await _storage.delete(key: StorageKeys.userJson);
    await clearPasswordResetSession();
  }

  Future<bool> isRememberMeEnabled() async {
    final value = await _storage.read(key: StorageKeys.rememberMeEnabled);
    return value == 'true';
  }

  /// Returns remembered email only. Passwords must never be persisted.
  Future<String?> getRememberedEmail() async {
    if (!await isRememberMeEnabled()) {
      return null;
    }

    final email = await _storage.read(key: StorageKeys.rememberedEmail);
    if (email == null || email.isEmpty) {
      return null;
    }

    return email;
  }

  Future<void> saveRememberMe({required bool enabled, String? email}) async {
    if (!enabled) {
      await clearRememberMe();
      return;
    }

    await _storage.write(key: StorageKeys.rememberMeEnabled, value: 'true');
    await _storage.write(key: StorageKeys.rememberedEmail, value: email ?? '');
    await _purgeLegacyRememberedPassword();
  }

  Future<void> clearRememberMe() async {
    await _storage.delete(key: StorageKeys.rememberMeEnabled);
    await _storage.delete(key: StorageKeys.rememberedEmail);
    await _purgeLegacyRememberedPassword();
  }

  /// Removes legacy password keys from older app versions without reading values.
  Future<void> purgeLegacyRememberedPassword() async {
    await _purgeLegacyRememberedPassword();
  }

  Future<void> _purgeLegacyRememberedPassword() async {
    await _storage.delete(key: StorageKeys.rememberedPassword);
  }

  Future<void> savePasswordResetSession({
    required String email,
    required String resetToken,
  }) async {
    await _storage.write(key: StorageKeys.passwordResetEmail, value: email);
    await _storage.write(
      key: StorageKeys.passwordResetToken,
      value: resetToken,
    );
  }

  Future<({String email, String resetToken})?> getPasswordResetSession() async {
    final email = await _storage.read(key: StorageKeys.passwordResetEmail);
    final resetToken = await _storage.read(key: StorageKeys.passwordResetToken);
    if (email == null ||
        email.isEmpty ||
        resetToken == null ||
        resetToken.isEmpty) {
      return null;
    }
    return (email: email, resetToken: resetToken);
  }

  Future<void> clearPasswordResetSession() async {
    await _storage.delete(key: StorageKeys.passwordResetEmail);
    await _storage.delete(key: StorageKeys.passwordResetToken);
  }

  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }
}
