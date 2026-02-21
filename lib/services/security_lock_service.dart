import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'local_database_service.dart';
import 'local_storage_service.dart';

class SecurityLockService {
  SecurityLockService._();

  static const String _kEnabledPrefix = 'security_lock_enabled_';
  static const String _kPromptedPrefix = 'security_lock_prompted_';

  static final LocalAuthentication _auth = LocalAuthentication();

  static String? _uid() => LocalStorageService.currentUserId;

  static String _enabledKey(String uid) => '$_kEnabledPrefix$uid';
  static String _promptedKey(String uid) => '$_kPromptedPrefix$uid';

  static Future<bool> isDeviceAuthAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported || canCheck;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> isEnabledForCurrentUser() async {
    final uid = _uid();
    if (uid == null || uid.isEmpty) return false;
    final raw = await LocalDatabaseService.getSetting(_enabledKey(uid));
    return raw == '1';
  }

  static Future<void> setEnabledForCurrentUser(bool enabled) async {
    final uid = _uid();
    if (uid == null || uid.isEmpty) return;
    await LocalDatabaseService.setSetting(_enabledKey(uid), enabled ? '1' : '0');
  }

  static Future<bool> wasPromptedForCurrentUser() async {
    final uid = _uid();
    if (uid == null || uid.isEmpty) return false;
    final raw = await LocalDatabaseService.getSetting(_promptedKey(uid));
    return raw == '1';
  }

  static Future<void> markPromptedForCurrentUser() async {
    final uid = _uid();
    if (uid == null || uid.isEmpty) return;
    await LocalDatabaseService.setSetting(_promptedKey(uid), '1');
  }

  static Future<bool> shouldOfferPromptForCurrentUser() async {
    final uid = _uid();
    if (uid == null || uid.isEmpty) return false;
    final enabled = await isEnabledForCurrentUser();
    if (enabled) return false;
    final prompted = await wasPromptedForCurrentUser();
    if (prompted) return false;
    return isDeviceAuthAvailable();
  }

  static Future<bool> requiresUnlockForCurrentUser() async {
    final enabled = await isEnabledForCurrentUser();
    if (!enabled) return false;
    return isDeviceAuthAvailable();
  }

  static Future<bool> authenticate({
    String reason = 'Desbloqueie para acessar suas financas.',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
