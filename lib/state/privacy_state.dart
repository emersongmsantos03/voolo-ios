import 'package:flutter/material.dart';

import '../core/utils/currency_utils.dart';
import '../services/local_database_service.dart';

class PrivacyState extends ChangeNotifier {
  static const String _kShowAmounts = 'show_amounts';
  bool _showAmounts = true;

  bool get showAmounts => _showAmounts;

  PrivacyState() {
    _load();
  }

  Future<void> _load() async {
    final raw = await LocalDatabaseService.getSetting(_kShowAmounts);
    if (raw == '0') {
      _showAmounts = false;
    } else {
      _showAmounts = true;
    }
    CurrencyUtils.hideValues = !_showAmounts;
    notifyListeners();
  }

  Future<void> setShowAmounts(bool value) async {
    if (_showAmounts == value) return;
    _showAmounts = value;
    CurrencyUtils.hideValues = !_showAmounts;
    await LocalDatabaseService.setSetting(_kShowAmounts, value ? '1' : '0');
    notifyListeners();
  }

  Future<void> toggle() => setShowAmounts(!_showAmounts);
}
