import 'package:flutter/foundation.dart';

import 'firestore_service.dart';
import 'local_database_service.dart';
import 'local_storage_service.dart';

class EngagementAnalyticsService {
  EngagementAnalyticsService._();

  static Future<void> _incrementCounter(String key) async {
    final raw = await LocalDatabaseService.getSetting(key);
    final current = int.tryParse(raw ?? '') ?? 0;
    await LocalDatabaseService.setSetting(key, '${current + 1}');
  }

  static Future<void> trackScreenView({required String surface}) {
    return trackEvent(
      type: 'screen_view',
      localCounterKey: 'analytics_screen_view_total',
      payload: {'surface': surface},
    );
  }

  static Future<void> trackEvent({
    required String type,
    String? localCounterKey,
    Map<String, Object?> payload = const <String, Object?>{},
  }) async {
    try {
      if (localCounterKey != null && localCounterKey.isNotEmpty) {
        await _incrementCounter(localCounterKey);
      }
      await _incrementCounter('analytics_event_$type');
      await LocalDatabaseService.setSetting(
        'analytics_event_last_at',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('EngagementAnalyticsService local track error: $e');
    }

    final uid = LocalStorageService.currentUserId;
    if (uid == null || uid.isEmpty) return;

    try {
      await FirestoreService.logEngagementEvent(
        uid: uid,
        type: type,
        payload: Map<String, dynamic>.from(payload),
      );
    } catch (e) {
      debugPrint('EngagementAnalyticsService remote track error: $e');
    }
  }
}
