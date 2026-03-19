import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../models/goal.dart';
import '../models/monthly_dashboard.dart';
import '../models/user_profile.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static const _dbFileName = 'jetx_local.json';
  static const _seedAssetPath = 'assets/local_db_seed.json';

  static bool _initialized = false;
  static File? _dbFile;
  static Map<String, dynamic> _data = {};

  static Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbFileName);
    _dbFile = File(path);

    await _loadOrSeed();
    _initialized = true;
  }

  static Future<void> _loadOrSeed() async {
    if (_dbFile == null) {
      throw StateError('LocalDatabaseService.init() must be called first.');
    }

    if (await _dbFile!.exists()) {
      try {
        final raw = await _dbFile!.readAsString();
        _data = jsonDecode(raw) as Map<String, dynamic>;
        _ensureShape();
        return;
      } catch (_) {
        // fallback to seed below
      }
    }

    _data = await _loadSeed();
    _ensureShape();
    await _persist();
  }

  static Future<Map<String, dynamic>> _loadSeed() async {
    try {
      final raw = await rootBundle.loadString(_seedAssetPath);
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {
        'users': <dynamic>[],
        'dashboards': <dynamic>[],
        'goals': <dynamic>[],
        'settings': <String, dynamic>{},
      };
    }
  }

  static void _ensureShape() {
    _data['users'] = _data['users'] as List<dynamic>? ?? <dynamic>[];
    _data['dashboards'] = _data['dashboards'] as List<dynamic>? ?? <dynamic>[];
    _data['goals'] = _data['goals'] as List<dynamic>? ?? <dynamic>[];
    _data['settings'] = _data['settings'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  static Future<void> _persist() async {
    if (_dbFile == null) {
      throw StateError('LocalDatabaseService.init() must be called first.');
    }
    final raw = jsonEncode(_data);
    await _dbFile!.writeAsString(raw);
  }

  static void _ensureInit() {
    if (!_initialized) {
      throw StateError('LocalDatabaseService.init() must be called first.');
    }
  }

  static Future<void> ensureSeedUser(String email) async {
    _ensureInit();
    final users = _data['users'] as List<dynamic>;
    final exists = users.any((u) {
      final map = u as Map<String, dynamic>;
      return (map['email'] as String).toLowerCase() == email.toLowerCase();
    });
    if (exists) return;

    final seed = await _loadSeed();
    final seedUsers = seed['users'] as List<dynamic>? ?? [];
    final match = seedUsers.cast<Map<String, dynamic>?>().firstWhere(
          (u) =>
              u != null &&
              (u['email'] as String?)?.toLowerCase() == email.toLowerCase(),
          orElse: () => null,
        );
    if (match != null) {
      users.add(match);
      await _persist();
    }
  }

  // ================= SETTINGS =================

  static Future<String?> getSetting(String key) async {
    _ensureInit();
    final settings = _data['settings'] as Map<String, dynamic>;
    final value = settings[key];
    return value?.toString();
  }

  static Future<void> setSetting(String key, String? value) async {
    _ensureInit();
    final settings = _data['settings'] as Map<String, dynamic>;
    if (value == null || value.isEmpty) {
      settings.remove(key);
    } else {
      settings[key] = value;
    }
    await _persist();
  }

  static Future<void> renameUserEmail(String oldEmail, String newEmail) async {
    _ensureInit();
    final oldNormalized = oldEmail.toLowerCase();
    final users = _data['users'] as List<dynamic>;
    for (final user in users) {
      final map = user as Map<String, dynamic>;
      final email = (map['email'] as String?)?.toLowerCase();
      if (email == oldNormalized) {
        map['email'] = newEmail;
      }
    }

    final dashboards = _data['dashboards'] as List<dynamic>;
    for (final dashboard in dashboards) {
      final map = dashboard as Map<String, dynamic>;
      final email = map['email']?.toString().toLowerCase();
      if (email == oldNormalized) {
        map['email'] = newEmail;
      }
    }

    final goals = _data['goals'] as List<dynamic>;
    for (final goal in goals) {
      final map = goal as Map<String, dynamic>;
      final email = map['email']?.toString().toLowerCase();
      if (email == oldNormalized) {
        map['email'] = newEmail;
      }
    }

    await _persist();
  }

  // ================= USERS =================

  static Future<List<UserProfile>> getUsers() async {
    _ensureInit();
    final users = _data['users'] as List<dynamic>;
    return users
        .map((u) => UserProfile.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  static Future<void> upsertUser(UserProfile user) async {
    _ensureInit();
    final users = _data['users'] as List<dynamic>;
    final idx = users.indexWhere((u) {
      final map = u as Map<String, dynamic>;
      return (map['email'] as String).toLowerCase() == user.email.toLowerCase();
    });
    if (idx >= 0) {
      users[idx] = user.toJson();
    } else {
      users.add(user.toJson());
    }
    await _persist();
  }

  // ================= DASHBOARDS =================

  static Future<List<MonthlyDashboard>> getDashboards(String email) async {
    _ensureInit();
    final dashboards = _data['dashboards'] as List<dynamic>;
    return dashboards
        .where((d) =>
            (d as Map<String, dynamic>)['email'].toString().toLowerCase() ==
            email.toLowerCase())
        .map((d) {
          final map = Map<String, dynamic>.from(d as Map<String, dynamic>);
          map.remove('email');
          return MonthlyDashboard.fromJson(map);
        })
        .toList();
  }

  static Future<void> replaceDashboards(
    String email,
    List<MonthlyDashboard> dashboards,
  ) async {
    _ensureInit();
    final list = _data['dashboards'] as List<dynamic>;
    list.removeWhere((d) =>
        (d as Map<String, dynamic>)['email'].toString().toLowerCase() ==
        email.toLowerCase());
    for (final dashboard in dashboards) {
      final map = dashboard.toJson();
      map['email'] = email;
      list.add(map);
    }
    await _persist();
  }

  // ================= GOALS =================

  static Future<List<Goal>> getGoals(String email) async {
    _ensureInit();
    final goals = _data['goals'] as List<dynamic>;
    return goals
        .where((g) =>
            (g as Map<String, dynamic>)['email'].toString().toLowerCase() ==
            email.toLowerCase())
        .map((g) {
          final map = Map<String, dynamic>.from(g as Map<String, dynamic>);
          map.remove('email');
          return Goal.fromJson(map);
        })
        .toList();
  }

  static Future<void> replaceGoals(String email, List<Goal> goals) async {
    _ensureInit();
    final list = _data['goals'] as List<dynamic>;
    list.removeWhere((g) =>
        (g as Map<String, dynamic>)['email'].toString().toLowerCase() ==
        email.toLowerCase());
    for (final goal in goals) {
      final map = goal.toJson();
      map['email'] = email;
      list.add(map);
    }
    await _persist();
  }
}
