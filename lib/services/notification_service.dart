import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/credit_card.dart';
import '../models/expense.dart';
import '../models/fixed_series.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

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

  static Future<void> _requestPermissions() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _createChannels() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelReminders,
        'Lembretes do Voolo',
        description: 'Avisos de vencimento e revisao de gastos.',
        importance: Importance.defaultImportance,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelEngagement,
        'Check-ins do Voolo',
        description: 'Lembretes gentis para manter o controle.',
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

  /// Agenda lembretes de contas fixas
  static Future<void> scheduleExpenseReminder(Expense expense) async {
    if (expense.dueDay == null || !expense.isFixed || expense.isCreditCard) return;
    await init();

    final dueDay = expense.dueDay!;
    final dueId = _expenseDueId(expense.id);
    final preId = _expensePreId(expense.id);

    final dueDate = _nextInstanceAt(dueDay, 9, 0);
    final dueDetails = _details(
      channelId: _channelReminders,
      channelName: 'Lembretes do Voolo',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin.zonedSchedule(
      dueId,
      'Vence hoje',
      '${expense.name} vence hoje. Confira o pagamento.',
      dueDate,
      dueDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );

    if (dueDay >= 4) {
      final preDate = _nextInstanceAt(dueDay - 3, 9, 0);
      await _plugin.zonedSchedule(
        preId,
        'Vencimento chegando',
        '${expense.name} vence em 3 dias. Antecipe para evitar juros.',
        preDate,
        dueDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } else {
      // If due day changed to 1-3, ensure any old "3 days before" reminder is removed.
      await _plugin.cancel(preId);
    }
  }

  /// Agenda lembretes de contas fixas (recorrências).
  static Future<void> scheduleFixedSeriesReminder(FixedSeries series) async {
    if (!series.isActive || series.dueDay == null || series.isCreditCard) return;
    await init();

    final dueDay = series.dueDay!;
    final dueId = _fixedSeriesDueId(series.seriesId);
    final preId = _fixedSeriesPreId(series.seriesId);

    final dueDate = _nextInstanceAt(dueDay, 9, 0);
    final details = _details(
      channelId: _channelReminders,
      channelName: 'Lembretes do Voolo',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin.zonedSchedule(
      dueId,
      'Vence hoje',
      '${series.name} vence hoje. Confira o pagamento.',
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
        'Vencimento chegando',
        '${series.name} vence em 3 dias. Antecipe para evitar juros.',
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

  /// Agenda lembretes de faturas de cartão (dia do vencimento e 3 dias antes).
  static Future<void> scheduleCreditCardBillReminder(CreditCard card) async {
    if (card.dueDay <= 0) return;
    await init();

    final dueDay = card.dueDay;
    final dueId = _cardDueId(card.id);
    final preId = _cardPreId(card.id);

    final dueDate = _nextInstanceAt(dueDay, 9, 0);
    final details = _details(
      channelId: _channelReminders,
      channelName: 'Lembretes do Voolo',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin.zonedSchedule(
      dueId,
      'Fatura vence hoje',
      'A fatura do cartão ${card.name} vence hoje. Confira o pagamento.',
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
        'Fatura chegando',
        'A fatura do cartão ${card.name} vence em 3 dias. Evite juros.',
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

  /// Lembretes suaves (sem spam): semanal + mensal.
  static Future<void> scheduleEngagementReminders() async {
    const dailyId = 9001; // legacy: cancel to avoid spam
    const weeklyId = 9002;
    const monthlyInvestId = 9003;

    await _plugin.cancel(dailyId);
    await _plugin.cancel(weeklyId);
    await _plugin.cancel(monthlyInvestId);

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
      'Fechamento da semana',
      'Confira seu resumo e ajuste o que for necessário.',
      nextSunday,
      _details(
        channelId: _channelEngagement,
        channelName: 'Check-ins do Voolo',
        importance: Importance.low,
        priority: Priority.low,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    // Lembrete mensal de investimento (gentil, sem insistência).
    final monthly = _nextInstanceAt(10, 19, 0);
    await _plugin.zonedSchedule(
      monthlyInvestId,
      'Lembrete de investimento',
      'Se fizer sentido, defina um valor para investir este mês.',
      monthly,
      _details(
        channelId: _channelEngagement,
        channelName: 'Check-ins do Voolo',
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
