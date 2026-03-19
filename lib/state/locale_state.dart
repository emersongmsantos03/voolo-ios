import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class LocaleState extends ChangeNotifier {
  Locale _locale = const Locale('pt', 'BR');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    NotificationService.setLocale(locale.languageCode);
    notifyListeners();
  }
}
