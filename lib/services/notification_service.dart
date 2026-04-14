import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/localization/app_strings.dart';
import '../models/credit_card.dart';
import '../models/expense.dart';
import '../models/fixed_series.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String _localeCode = 'pt';

  static const String _channelReminders = 'voolo_reminders';
  static const String _channelEngagement = 'voolo_engagement';

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(initSettings);

    await _createChannels();
    await _requestPermissions();
    await scheduleEngagementReminders();

    _initialized = true;
  }

  static Future<void> setLocale(String code) async {
    _localeCode = code;
    if (!_initialized) return;
    await _createChannels();
    await scheduleEngagementReminders();
  }

  static String _t(String key) => AppStrings.byCode(_localeCode, key);

  static String _tr(String key, Map<String, String> vars) =>
      AppStrings.trByCode(_localeCode, key, vars);

  static Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      AndroidNotificationChannel(
        _channelReminders,
        _t('notif_channel_reminders_name'),
        description: _t('notif_channel_reminders_desc'),
        importance: Importance.defaultImportance,
      ),
    );
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        _channelEngagement,
        _t('notif_channel_engagement_name'),
        description: _t('notif_channel_engagement_desc'),
        importance: Importance.low,
      ),
    );
  }

  static NotificationDetails _details({
    required String channelId,
    required String channelName,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: importance,
        priority: priority,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  static int _stableId(String seed, int suffix) {
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return (hash % 100000) + suffix;
  }

  static String _expenseSeed(String expenseId) => 'expense:$expenseId';
  static String _fixedSeriesSeed(String seriesId) => 'fixed_series:$seriesId';
  static String _creditCardSeed(String cardId) => 'credit_card:$cardId';

  static int _expenseDueId(String expenseId) =>
      _stableId(_expenseSeed(expenseId), 1001);
  static int _expensePreId(String expenseId) =>
      _stableId(_expenseSeed(expenseId), 1002);
  static int _fixedSeriesDueId(String seriesId) =>
      _stableId(_fixedSeriesSeed(seriesId), 1101);
  static int _fixedSeriesPreId(String seriesId) =>
      _stableId(_fixedSeriesSeed(seriesId), 1102);
  static int _cardDueId(String cardId) =>
      _stableId(_creditCardSeed(cardId), 1201);
  static int _cardPreId(String cardId) =>
      _stableId(_creditCardSeed(cardId), 1202);

  static bool _isBusinessDay(tz.TZDateTime day) {
    return day.weekday >= DateTime.monday && day.weekday <= DateTime.friday;
  }

  static tz.TZDateTime _fifthBusinessDayAt(
    int hour,
    int minute, {
    tz.TZDateTime? anchor,
  }) {
    final now = anchor ?? tz.TZDateTime.now(tz.local);

    tz.TZDateTime computeForMonth(int year, int month) {
      var current = tz.TZDateTime(tz.local, year, month, 1, hour, minute);
      var businessDays = 0;
      while (true) {
        if (_isBusinessDay(current)) {
          businessDays++;
          if (businessDays == 5) return current;
        }
        current = current.add(const Duration(days: 1));
      }
    }

    final thisMonth = computeForMonth(now.year, now.month);
    if (thisMonth.isAfter(now)) return thisMonth;
    return computeForMonth(now.year, now.month + 1);
  }

  static tz.TZDateTime _nextInstanceAt(
    int day,
    int hour,
    int minute,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        day,
        hour,
        minute,
      );
    }
    return scheduled;
  }

  static Future<void> scheduleExpenseReminder(Expense expense) async {
    if (expense.dueDay == null || !expense.isFixed || expense.isCreditCard) {
      return;
    }
    await init();

    final dueDay = expense.dueDay!;
    final dueId = _expenseDueId(expense.id);
    final preId = _expensePreId(expense.id);

    final dueDate = _nextInstanceAt(dueDay, 9, 0);
    final details = _details(
      channelId: _channelReminders,
      channelName: _t('notif_channel_reminders_name'),
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin.zonedSchedule(
      dueId,
      _t('notif_due_today_title'),
      _tr('notif_due_today_body', {'name': expense.name}),
      dueDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );

    if (dueDay >= 4) {
      final preDate = _nextInstanceAt(dueDay - 3, 9, 0);
      await _plugin.zonedSchedule(
        preId,
        _t('notif_due_soon_title'),
        _tr('notif_due_soon_body', {'name': expense.name}),
        preDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } else {
      await _plugin.cancel(preId);
    }
  }

  static Future<void> scheduleFixedSeriesReminder(FixedSeries series) async {
    if (!series.isActive || series.dueDay == null || series.isCreditCard) {
      return;
    }
    await init();

    final dueDay = series.dueDay!;
    final dueId = _fixedSeriesDueId(series.seriesId);
    final preId = _fixedSeriesPreId(series.seriesId);

    final dueDate = _nextInstanceAt(dueDay, 9, 0);
    final details = _details(
      channelId: _channelReminders,
      channelName: _t('notif_channel_reminders_name'),
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin.zonedSchedule(
      dueId,
      _t('notif_due_today_title'),
      _tr('notif_due_today_body', {'name': series.name}),
      dueDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );

    if (dueDay >= 4) {
      final preDate = _nextInstanceAt(dueDay - 3, 9, 0);
      await _plugin.zonedSchedule(
        preId,
        _t('notif_due_soon_title'),
        _tr('notif_due_soon_body', {'name': series.name}),
        preDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } else {
      await _plugin.cancel(preId);
    }
  }

  static Future<void> scheduleCreditCardBillReminder(CreditCard card) async {
    if (card.dueDay <= 0) return;
    await init();

    final dueDay = card.dueDay;
    final dueId = _cardDueId(card.id);
    final preId = _cardPreId(card.id);

    final dueDate = _nextInstanceAt(dueDay, 9, 0);
    final details = _details(
      channelId: _channelReminders,
      channelName: _t('notif_channel_reminders_name'),
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin.zonedSchedule(
      dueId,
      _t('notif_card_due_today_title'),
      _tr('notif_card_due_today_body', {'name': card.name}),
      dueDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );

    if (dueDay >= 4) {
      final preDate = _nextInstanceAt(dueDay - 3, 9, 0);
      await _plugin.zonedSchedule(
        preId,
        _t('notif_card_due_soon_title'),
        _tr('notif_card_due_soon_body', {'name': card.name}),
        preDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } else {
      await _plugin.cancel(preId);
    }
  }

  static Future<void> cancelExpenseReminder(String expenseId) async {
    await init();
    await _plugin.cancel(_expenseDueId(expenseId));
    await _plugin.cancel(_expensePreId(expenseId));
  }

  static Future<void> cancelFixedSeriesReminder(String seriesId) async {
    await init();
    await _plugin.cancel(_fixedSeriesDueId(seriesId));
    await _plugin.cancel(_fixedSeriesPreId(seriesId));
  }

  static Future<void> cancelCreditCardBillReminder(String cardId) async {
    await init();
    await _plugin.cancel(_cardDueId(cardId));
    await _plugin.cancel(_cardPreId(cardId));
  }

  static Future<void> scheduleEngagementReminders() async {
    const dailyId = 9001;
    const weeklyId = 9002;
    const monthlyEntriesId = 9003;

    await _plugin.cancel(dailyId);
    await _plugin.cancel(weeklyId);
    await _plugin.cancel(monthlyEntriesId);

    final now = tz.TZDateTime.now(tz.local);
    var nextSunday = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10,
      0,
    );
    while (nextSunday.weekday != DateTime.sunday || nextSunday.isBefore(now)) {
      nextSunday = nextSunday.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      weeklyId,
      _t('notif_weekly_review_title'),
      _t('notif_weekly_review_body'),
      nextSunday,
      _details(
        channelId: _channelEngagement,
        channelName: _t('notif_channel_engagement_name'),
        importance: Importance.low,
        priority: Priority.low,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    final monthly = _fifthBusinessDayAt(9, 0);
    await _plugin.zonedSchedule(
      monthlyEntriesId,
      _t('notif_monthly_entries_title'),
      _t('notif_monthly_entries_body'),
      monthly,
      _details(
        channelId: _channelEngagement,
        channelName: _t('notif_channel_engagement_name'),
        importance: Importance.low,
        priority: Priority.low,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }
}
