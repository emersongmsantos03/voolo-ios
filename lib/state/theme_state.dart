import 'package:flutter/material.dart';

import '../services/local_database_service.dart';

class ThemeState extends ChangeNotifier {
  static const String _kThemeMode = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeState() {
    _load();
  }

  Future<void> _load() async {
    final raw = await LocalDatabaseService.getSetting(_kThemeMode);
    if (raw == 'light') {
      _mode = ThemeMode.light;
    } else if (raw == 'dark') {
      _mode = ThemeMode.dark;
    } else {
      _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await LocalDatabaseService.setSetting(_kThemeMode, value);
    notifyListeners();
  }
}
