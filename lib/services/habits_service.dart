import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'local_database_service.dart';
import 'firestore_service.dart';

class HabitState {
  final String date;
  final List<String> done;
  final int streak;
  final String? lastCompleteDate;
  final int updatedAtMs;

  const HabitState({
    required this.date,
    required this.done,
    required this.streak,
    required this.lastCompleteDate,
    required this.updatedAtMs,
  });

  HabitState copyWith({
    String? date,
    List<String>? done,
    int? streak,
    String? lastCompleteDate,
    int? updatedAtMs,
  }) {
    return HabitState(
      date: date ?? this.date,
      done: done ?? this.done,
      streak: streak ?? this.streak,
      lastCompleteDate: lastCompleteDate ?? this.lastCompleteDate,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}

class HabitsService {
  HabitsService._();

  static const _kHabitState = 'habit_state_v1';
  static final ValueNotifier<HabitState?> notifier = ValueNotifier(null);
  static StreamSubscription<Map<String, dynamic>?>? _remoteSub;
  static String? _uid;

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _yesterdayKey() {
    final now = DateTime.now().subtract(const Duration(days: 1));
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static HabitState _normalizeForToday(HabitState state) {
    final today = _todayKey();
    if (state.date == today) return state;
    return state.copyWith(date: today, done: const []);
  }

  static Map<String, dynamic> _toMap(HabitState state) {
    return {
      'date': state.date,
      'done': state.done,
      'streak': state.streak,
      'lastCompleteDate': state.lastCompleteDate,
      'updatedAtMs': state.updatedAtMs,
    };
  }

  static HabitState _fromMap(Map<String, dynamic> data) {
    final date = (data['date'] as String?) ?? _todayKey();
    final done = (data['done'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];
    final streak = (data['streak'] as num?)?.toInt() ?? 0;
    final lastCompleteDate = data['lastCompleteDate'] as String?;
    final updatedAtMs = (data['updatedAtMs'] as num?)?.toInt() ?? 0;
    return HabitState(
      date: date,
      done: done,
      streak: streak,
      lastCompleteDate: lastCompleteDate,
      updatedAtMs: updatedAtMs,
    );
  }

  static Future<void> startSync({required String uid}) async {
    if (uid.isEmpty) return;
    if (_uid == uid && _remoteSub != null) return;

    await stopSync();
    _uid = uid;

    // Load local immediately for UI.
    final local = await load();
    notifier.value = local;

    _remoteSub = FirestoreService.watchHabitsState(uid).listen((remote) async {
      final localState = notifier.value ?? await load();

      if (remote == null) {
        // Seed remote from local when the doc doesn't exist yet.
        try {
          await FirestoreService.saveHabitsState(uid, _toMap(localState));
        } catch (_) {
          // ignore
        }
        return;
      }

      final remoteState = _normalizeForToday(_fromMap(remote));
      final localUpdated = localState.updatedAtMs;
      final remoteUpdated = remoteState.updatedAtMs;
      if (remoteUpdated <= localUpdated) return;

      try {
        await LocalDatabaseService.setSetting(_kHabitState, jsonEncode(_toMap(remoteState)));
      } catch (_) {
        // ignore local persistence errors
      }
      notifier.value = remoteState;
    });
  }

  static Future<void> stopSync() async {
    await _remoteSub?.cancel();
    _remoteSub = null;
    _uid = null;
  }

  static Future<HabitState> load() async {
    final raw = await LocalDatabaseService.getSetting(_kHabitState);
    if (raw == null || raw.isEmpty) {
      final next = HabitState(
        date: _todayKey(),
        done: const [],
        streak: 0,
        lastCompleteDate: null,
        updatedAtMs: 0,
      );
      notifier.value = next;
      return next;
    }
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final parsed = _fromMap(data);
      final normalized = _normalizeForToday(parsed);
      notifier.value = normalized;
      return normalized;
    } catch (_) {
      final next = HabitState(
        date: _todayKey(),
        done: const [],
        streak: 0,
        lastCompleteDate: null,
        updatedAtMs: 0,
      );
      notifier.value = next;
      return next;
    }
  }

  static Future<HabitState> toggleHabit({
    required String habitId,
    required int totalHabits,
  }) async {
    var state = _normalizeForToday(await load());
    final today = _todayKey();

    final done = List<String>.from(state.done);
    if (done.contains(habitId)) {
      done.remove(habitId);
    } else {
      done.add(habitId);
    }

    var streak = state.streak;
    var lastCompleteDate = state.lastCompleteDate;
    if (done.length == totalHabits) {
      if (lastCompleteDate != today) {
        streak = lastCompleteDate == _yesterdayKey() ? streak + 1 : 1;
        lastCompleteDate = today;
      }
    }

    final next = state.copyWith(
      date: today,
      done: done,
      streak: streak,
      lastCompleteDate: lastCompleteDate,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    await LocalDatabaseService.setSetting(
      _kHabitState,
      jsonEncode({
        ..._toMap(next),
      }),
    );
    notifier.value = next;

    final uid = _uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        await FirestoreService.saveHabitsState(uid, _toMap(next));
      } catch (_) {
        // ignore
      }
    }
    return next;
  }
}
