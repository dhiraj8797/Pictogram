import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  static const _channel = MethodChannel('com.pictogram.app/security');
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );

  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  // ── Screen Security ─────────────────────────────────────────────────────────

  /// Enables FLAG_SECURE — blocks screenshots and screen recording
  Future<void> enableSecureScreen() async {
    try {
      await _channel.invokeMethod('enableSecureScreen');
    } catch (_) {}
  }

  /// Disables FLAG_SECURE — allows screenshots (for content screens)
  Future<void> disableSecureScreen() async {
    try {
      await _channel.invokeMethod('disableSecureScreen');
    } catch (_) {}
  }

  // ── Device Integrity ────────────────────────────────────────────────────────

  /// Returns true if device appears to be rooted
  Future<bool> isRooted() async {
    try {
      return await _channel.invokeMethod<bool>('isRooted') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if running on an emulator
  Future<bool> isEmulator() async {
    try {
      return await _channel.invokeMethod<bool>('isEmulator') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the environment is considered risky
  Future<bool> isEnvironmentRisky() async {
    final rooted = await isRooted();
    final emulator = await isEmulator();
    return rooted || emulator;
  }

  // ── Secure Storage ──────────────────────────────────────────────────────────

  Future<void> secureWrite(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> secureRead(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> secureDelete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> secureDeleteAll() async {
    await _storage.deleteAll();
  }

  // ── Session Keys ─────────────────────────────────────────────────────────────

  Future<void> saveSessionToken(String token) async =>
      secureWrite('session_token', token);

  Future<String?> getSessionToken() async => secureRead('session_token');

  Future<void> clearSession() async => secureDeleteAll();
}
