import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/goal.dart';
import '../models/income_source.dart';
import '../models/fixed_series.dart';
import '../models/monthly_dashboard.dart';
import '../models/user_profile.dart';
import '../models/expense.dart';
import '../models/v2/category_key.dart';
import '../models/v2/enums.dart';
import '../models/v2/reference_month.dart';
import '../models/budget_v2.dart';
import '../models/debt_v2.dart';
import '../models/debt_plan_v2.dart';
import '../models/investment_profile.dart';
import '../models/investment_plan_doc.dart';

class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? _currentUid() => _auth.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _db.collection('users').doc(uid);
  }

  static DocumentReference<Map<String, dynamic>> _legacyUserDoc(String email) {
    return _db.collection('users').doc(email.trim().toLowerCase());
  }

  static CollectionReference<Map<String, dynamic>> _dashboards(String uid) {
    return _userDoc(uid).collection('dashboards');
  }

  static CollectionReference<Map<String, dynamic>> _incomes(String uid) {
    return _userDoc(uid).collection('incomes');
  }

  static CollectionReference<Map<String, dynamic>> _goals(String uid) {
    return _userDoc(uid).collection('goals');
  }

  static CollectionReference<Map<String, dynamic>> _budgets(String uid) {
    return _userDoc(uid).collection('budgets');
  }

  static CollectionReference<Map<String, dynamic>> _budgetSuggestionRuns(
      String uid) {
    return _userDoc(uid).collection('budgetSuggestionRuns');
  }

  static CollectionReference<Map<String, dynamic>> _debts(String uid) {
    return _userDoc(uid).collection('debts');
  }

  static CollectionReference<Map<String, dynamic>> _debtPlans(String uid) {
    return _userDoc(uid).collection('debtPlans');
  }

  static DocumentReference<Map<String, dynamic>> _investmentProfile(
      String uid) {
    return _userDoc(uid).collection('investmentProfile').doc('current');
  }

  static DocumentReference<Map<String, dynamic>> _investmentPlan(String uid) {
    return _userDoc(uid).collection('investmentPlan').doc('current');
  }

  // --- FIXED SERIES (Recurring Monthly) ---
  static CollectionReference<Map<String, dynamic>> _fixedSeries(String uid) {
    return _userDoc(uid).collection('fixedSeries');
  }

  static Future<List<FixedSeries>> getFixedSeries(String uid) async {
    final snap = await _fixedSeries(uid).get();
    return snap.docs
        .map((d) => FixedSeries.fromJson(d.data(), id: d.id))
        .toList();
  }

  static Future<void> saveFixedSeries(String uid, FixedSeries series) async {
    final ref = _fixedSeries(uid).doc(series.seriesId);
    final data = series.toJson();
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    if (!amount.isFinite || amount <= 0) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Invalid fixed series amount',
      );
    }
    final snap = await ref.get();
    final exists = snap.exists;
    final prev = exists ? snap.data() : null;
    await ref.set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
        if (prev != null && prev.containsKey('createdAt'))
          'createdAt': prev['createdAt']
        else
          'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> endFixedSeries(
      String uid, String seriesId, String endMonthYear) async {
    final ref = _fixedSeries(uid).doc(seriesId);
    await ref.set(
      {
        'isActive': false,
        'endMonthYear': endMonthYear,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> addFixedExclusion(
      String uid, String monthYear, String seriesId) async {
    final ref = _dashboards(uid).doc(monthYear);
    await ref.set(
      {
        'fixedExclusions': FieldValue.arrayUnion([seriesId]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> deleteFixedOccurrencesForMonth(
    String uid,
    String seriesId,
    String monthYear,
  ) async {
    final parts = monthYear.split('-');
    if (parts.length != 2) return;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) return;

    final startDate = DateTime(year, month, 1, 0, 0, 0);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59, 999);

    // Avoid composite indexes (seriesId + range) by fetching by seriesId only
    // and filtering client-side. Also supports legacy docs that only have
    // dueDate (or non-Timestamp date formats).
    final snap =
        await _transactions(uid).where('seriesId', isEqualTo: seriesId).get();
    if (snap.docs.isEmpty) return;

    DateTime? readDate(Map<String, dynamic> data) {
      final raw = data['dueDate'] ?? data['date'];
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    final refs = <DocumentReference<Map<String, dynamic>>>[];
    for (final doc in snap.docs) {
      final dt = readDate(doc.data());
      if (dt == null) continue;
      if (dt.isBefore(startDate) || dt.isAfter(endDate)) continue;
      refs.add(doc.reference);
    }
    if (refs.isEmpty) return;

    const chunkSize = 450;
    for (var i = 0; i < refs.length; i += chunkSize) {
      final batch = _db.batch();
      final chunk = refs.sublist(i, min(i + chunkSize, refs.length));
      for (final r in chunk) {
        batch.delete(r);
      }
      await batch.commit();
    }
  }

  static Future<void> deleteFixedSeriesFromDate(
    String uid,
    String seriesId,
    DateTime fromDate,
  ) async {
    final snap =
        await _transactions(uid).where('seriesId', isEqualTo: seriesId).get();
    if (snap.docs.isEmpty) return;

    DateTime? readDate(Map<String, dynamic> data) {
      final raw = data['dueDate'] ?? data['date'];
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    final refs = <DocumentReference<Map<String, dynamic>>>[];
    for (final doc in snap.docs) {
      final dt = readDate(doc.data());
      if (dt == null) continue;
      if (dt.isBefore(fromDate)) continue;
      refs.add(doc.reference);
    }
    if (refs.isEmpty) return;

    const chunkSize = 450;
    for (var i = 0; i < refs.length; i += chunkSize) {
      final batch = _db.batch();
      final chunk = refs.sublist(i, min(i + chunkSize, refs.length));
      for (final r in chunk) {
        batch.delete(r);
      }
      await batch.commit();
    }
  }

  static Stream<List<IncomeSource>> watchIncomes(String uid) {
    return _incomes(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => IncomeSource.fromJson(doc.data(), id: doc.id))
          .toList();
    });
  }

  static Stream<List<BudgetV2>> watchBudgets(String uid, String monthYear) {
    // Keep query simple to avoid composite-index requirements.
    // Filter/sort client-side (aligned with voolo-web).
    Query<Map<String, dynamic>> q = _budgets(uid);
    if (monthYear.isNotEmpty) {
      q = q.where('referenceMonth', isEqualTo: monthYear);
    }
    return q.snapshots().map((snapshot) {
      // Enforce v2 only (server/admin may have legacy docs)
      final filtered = <BudgetV2>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final schema = (data['schemaVersion'] as num?)?.toInt();
        if (schema != 2) continue;
        filtered.add(BudgetV2.fromJson(data, id: doc.id));
      }
      filtered.sort((a, b) => a.categoryKey.compareTo(b.categoryKey));
      return filtered;
    });
  }

  static Future<void> saveBudgetLimit({
    required String uid,
    required String monthYear,
    required String categoryKey,
    required double limitAmount,
    bool? essential,
  }) async {
    final id = '${monthYear}_$categoryKey';
    final ref = _budgets(uid).doc(id);
    final existingSnap = await ref.get();
    final existing = existingSnap.data();

    final payload = <String, dynamic>{
      'schemaVersion': SchemaVersion.v2,
      'referenceMonth': monthYear,
      'categoryKey': categoryKey,
      'limitAmount': limitAmount,
      if (essential != null) 'essential': essential,
      'updatedAt': FieldValue.serverTimestamp(),
      'sourceApp': SourceApp.flutter,
    };

    // Rules require createdAt/createdBy for v2 docs; keep immutable if present.
    if (existing == null || !existing.containsKey('createdAt')) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    if (existing == null || !existing.containsKey('createdBy')) {
      payload['createdBy'] = uid;
    }

    await ref.set(payload, SetOptions(merge: true));
  }

  static Future<void> logBudgetSuggestionRun({
    required String uid,
    required String monthYear,
    required String categoryKey,
    required double suggestedAmount,
    required bool replicateFuture,
  }) async {
    final now = DateTime.now();
    final id = '${monthYear}_${now.millisecondsSinceEpoch}_$categoryKey';
    await _budgetSuggestionRuns(uid).doc(id).set(
      {
        'schemaVersion': 1,
        'referenceMonth': monthYear,
        'categoryKey': categoryKey,
        'suggestedAmount': suggestedAmount,
        'replicateFuture': replicateFuture,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
        'sourceApp': SourceApp.flutter,
      },
      SetOptions(merge: true),
    );
  }

  static Stream<List<DebtV2>> watchDebts(String uid) {
    // Keep query simple to avoid composite-index requirements (filter v2 client-side).
    final q = _debts(uid).orderBy('totalAmount', descending: true);
    return q.snapshots().map((snapshot) {
      final out = <DebtV2>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final schema = (data['schemaVersion'] as num?)?.toInt();
        if (schema != 2) continue;
        out.add(DebtV2.fromJson(data, id: doc.id));
      }
      return out;
    }).handleError((_) {
      // Swallow stream errors to avoid crashing the UI when an index is missing.
    });
  }

  static String debtSeriesIdFor(String debtId) => 'debt_$debtId';

  static String _normalizeSeriesName(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static int _djb2Hash(String input) {
    var hash = 5381;
    for (final codeUnit in input.codeUnits) {
      hash = ((hash << 5) + hash) ^ codeUnit;
    }
    return hash & 0x7fffffff;
  }

  static String _toBase36(int value) {
    const chars = '0123456789abcdefghijklmnopqrstuvwxyz';
    var v = value;
    if (v == 0) return '0';
    final out = StringBuffer();
    while (v > 0) {
      out.write(chars[v % 36]);
      v ~/= 36;
    }
    return out.toString().split('').reversed.join();
  }

  static String? fixedSeriesIdForExpense(Expense tx) {
    final name = _normalizeSeriesName(tx.name);
    final amount = tx.amount.isFinite ? tx.amount : 0.0;
    final category = _normalizeSeriesName(
        toCategoryKey(tx.category.name) ?? tx.category.name);
    final day = (tx.dueDay != null && tx.dueDay! > 0) ? tx.dueDay! : 0;
    final isCreditCard = tx.isCreditCard ? 'cc' : 'no';
    final cardId = tx.creditCardId ?? '';

    final sig = [
      name,
      amount.toStringAsFixed(2),
      category,
      day.toString(),
      isCreditCard,
      cardId,
    ].join('|');
    if (sig == '||0|no|') return null;
    final hash = _toBase36(_djb2Hash(sig));
    return 'fix_$hash';
  }

  static Future<String> saveDebt(String uid, DebtV2 debt) async {
    final ref = debt.id.isEmpty ? _debts(uid).doc() : _debts(uid).doc(debt.id);
    final data = debt.toJson();

    final snap = await ref.get();
    final exists = snap.exists;
    final prev = exists ? snap.data() : null;

    data['updatedAt'] = FieldValue.serverTimestamp();
    data['createdBy'] = uid;
    data['sourceApp'] = SourceApp.flutter;
    if (prev != null && prev.containsKey('createdAt')) {
      data['createdAt'] = prev['createdAt'];
    } else {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await ref.set(data, SetOptions(merge: true));
    return ref.id;
  }

  static Future<void> deleteDebt(String uid, String debtId) async {
    final debtRef = _debts(uid).doc(debtId);

    String seriesId = debtSeriesIdFor(debtId);
    try {
      final snap = await debtRef.get();
      final data = snap.data();
      final explicit = data?['fixedSeriesId']?.toString().trim();
      if (explicit != null && explicit.isNotEmpty) {
        seriesId = explicit;
      }
    } catch (_) {
      // ignore: fall back to computed series id
    }

    final refs = <DocumentReference<Map<String, dynamic>>>[];

    try {
      final bySeries =
          await _transactions(uid).where('seriesId', isEqualTo: seriesId).get();
      refs.addAll(bySeries.docs.map((d) => d.reference));
    } catch (_) {
      // ignore
    }

    try {
      final byDebt =
          await _transactions(uid).where('debtId', isEqualTo: debtId).get();
      refs.addAll(byDebt.docs.map((d) => d.reference));
    } catch (_) {
      // ignore
    }

    if (refs.isNotEmpty) {
      final unique = <String, DocumentReference<Map<String, dynamic>>>{};
      for (final r in refs) {
        unique[r.path] = r;
      }
      final all = unique.values.toList();
      const chunkSize = 450;
      for (var i = 0; i < all.length; i += chunkSize) {
        final batch = _db.batch();
        final chunk = all.sublist(i, min(i + chunkSize, all.length));
        for (final r in chunk) {
          batch.delete(r);
        }
        await batch.commit();
      }
    }

    // Remove the fixed series doc to stop future occurrences.
    try {
      await _fixedSeries(uid).doc(seriesId).delete();
    } catch (_) {
      // ignore: might not exist
    }

    await debtRef.delete();
  }

  static DateTime _dueDateForMonthYear(String monthYear, int dueDay) {
    final parts = monthYear.split('-');
    final year = int.tryParse(parts.isNotEmpty ? parts[0] : '');
    final month = int.tryParse(parts.length > 1 ? parts[1] : '');
    if (year == null || month == null || month < 1 || month > 12) {
      return DateTime.now();
    }
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = dueDay.clamp(1, daysInMonth);
    return DateTime(year, month, day);
  }

  static Future<void> ensureDebtFixedSeries(String uid, DebtV2 debt) async {
    if (!debt.isInstallmentDebt) return;
    final debtId = debt.id;
    if (debtId.isEmpty) return;

    final seriesId = debt.fixedSeriesId ?? debtSeriesIdFor(debtId);
    final dueDay = debt.installmentDueDay ?? 1;
    final amount = debt.installmentAmount ?? 0.0;
    if (!amount.isFinite || amount <= 0) return;

    await saveFixedSeries(
      uid,
      FixedSeries(
        seriesId: seriesId,
        name: debt.creditorName.trim().isEmpty ? 'Dívidas' : debt.creditorName,
        amount: amount,
        category: ExpenseCategory.dividas,
        dueDay: dueDay,
        isCreditCard: false,
        creditCardId: null,
        isActive: true,
        endMonthYear: null,
      ),
    );

    // Keep the link on the debt doc (best-effort).
    await _debts(uid).doc(debtId).set(
      {
        'fixedSeriesId': seriesId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> ensureDebtTransactionForMonth(
    String uid, {
    required DebtV2 debt,
    required String monthYear,
  }) async {
    if (!debt.isInstallmentDebt) return;
    if (!debt.isWithinInstallmentWindow(monthYear)) return;

    final debtId = debt.id;
    if (debtId.isEmpty) return;

    final seriesId = debt.fixedSeriesId ?? debtSeriesIdFor(debtId);
    final dueDay = debt.installmentDueDay ?? 1;
    final amount = debt.installmentAmount ?? 0.0;
    if (!amount.isFinite || amount <= 0) return;

    final txId = '${seriesId}_$monthYear';
    final isPaid = debt.paidInstallmentMonths[monthYear] == true;
    final date = _dueDateForMonthYear(monthYear, dueDay);

    final tx = Expense(
      id: txId,
      name: debt.creditorName.trim().isEmpty ? 'Dívidas' : debt.creditorName,
      type: ExpenseType.fixed,
      category: ExpenseCategory.dividas,
      amount: amount,
      date: date,
      txType: TxType.debtPayment,
      seriesId: seriesId,
      debtId: debtId,
      dueDay: dueDay,
      isPaid: isPaid,
      isCreditCard: false,
      creditCardId: null,
      isCardRecurring: false,
    );

    // Prefer deterministic id; if legacy docs exist for the same month, migrate.
    final q = await _transactions(uid)
        .where('seriesId', isEqualTo: seriesId)
        .where('referenceMonth', isEqualTo: monthYear)
        .get();

    final batch = _db.batch();
    bool hasDeterministic = false;
    Map<String, dynamic>? legacyData;
    String? legacyId;

    for (final doc in q.docs) {
      if (doc.id == txId) {
        hasDeterministic = true;
        break;
      }
      legacyData ??= doc.data();
      legacyId ??= doc.id;
    }

    if (!hasDeterministic && legacyData != null) {
      batch.set(
        _transactions(uid).doc(txId),
        {
          ...legacyData,
          'id': txId,
          'seriesId': seriesId,
          'debtId': debtId,
          'categoryKey': 'DIVIDAS',
          'type': TxType.debtPayment,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      for (final doc in q.docs) {
        if (doc.id == txId) continue;
        batch.delete(doc.reference);
      }
      await batch.commit();
      return;
    }

    // Idempotent upsert (no duplicates).
    await saveTransaction(uid, tx);
  }

  static Future<void> setDebtInstallmentPaidForMonth(
    String uid, {
    required DebtV2 debt,
    required String monthYear,
    required bool isPaid,
  }) async {
    if (!debt.isInstallmentDebt) return;
    if (!debt.isWithinInstallmentWindow(monthYear)) return;
    if (debt.id.isEmpty) return;

    await ensureDebtFixedSeries(uid, debt);
    await ensureDebtTransactionForMonth(uid, debt: debt, monthYear: monthYear);

    final seriesId = debt.fixedSeriesId ?? debtSeriesIdFor(debt.id);
    final txId = '${seriesId}_$monthYear';

    await _db.runTransaction((tx) async {
      final debtRef = _debts(uid).doc(debt.id);
      final debtSnap = await tx.get(debtRef);
      final data = debtSnap.data() ?? const <String, dynamic>{};
      final total = (data['installmentTotal'] as num?)?.toInt() ??
          (debt.installmentTotal ?? 0);
      final status = data['status']?.toString() ?? debt.status;

      final rawPaid = data['paidInstallmentMonths'];
      final paid = <String, bool>{};
      if (rawPaid is Map) {
        for (final e in rawPaid.entries) {
          paid[e.key.toString()] = e.value == true;
        }
      } else {
        paid.addAll(debt.paidInstallmentMonths);
      }
      paid[monthYear] = isPaid;

      final paidCount = paid.values.where((v) => v == true).length;
      String? lastPaidMonthYear;
      for (final e in paid.entries) {
        if (e.value != true) continue;
        final k = e.key.toString();
        if (lastPaidMonthYear == null || k.compareTo(lastPaidMonthYear) > 0) {
          lastPaidMonthYear = k;
        }
      }
      final nextStatus = (total > 0 && paidCount >= total)
          ? DebtStatus.paid
          : (status == DebtStatus.negotiating
              ? DebtStatus.negotiating
              : DebtStatus.active);

      tx.set(
        debtRef,
        {
          'paidInstallmentMonths': paid,
          'status': nextStatus,
          if (nextStatus == DebtStatus.paid) ...{
            'paidAt': FieldValue.serverTimestamp(),
            'paidReason': 'installments_fully_paid',
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final seriesRef = _fixedSeries(uid).doc(seriesId);
      if (nextStatus == DebtStatus.paid) {
        tx.set(
          seriesRef,
          {
            'isActive': false,
            'endMonthYear': lastPaidMonthYear ?? monthYear,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else if (!isPaid && status == DebtStatus.paid) {
        tx.set(
          seriesRef,
          {
            'isActive': true,
            'endMonthYear': null,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      final txRef = _transactions(uid).doc(txId);
      tx.set(
        txRef,
        {
          'id': txId,
          'seriesId': seriesId,
          'debtId': debt.id,
          'status': isPaid ? TxStatus.paid : TxStatus.pending,
          'paidAt': isPaid ? FieldValue.serverTimestamp() : null,
          'isPaid': isPaid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  static Future<void> syncDebtPaidFromTransaction(
    String uid, {
    required String debtId,
    required String monthYear,
    required bool isPaid,
  }) async {
    if (debtId.isEmpty) return;
    await _db.runTransaction((tx) async {
      final ref = _debts(uid).doc(debtId);
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? const <String, dynamic>{};

      final installmentTotal = (data['installmentTotal'] as num?)?.toInt();
      final installmentStart = data['installmentStartMonthYear']?.toString();
      if (installmentTotal == null ||
          installmentTotal <= 0 ||
          installmentStart == null ||
          installmentStart.isEmpty) {
        return;
      }

      // Window check (never auto-pay/auto-finish based on time).
      if (monthYear.compareTo(installmentStart) < 0) return;
      final parts = installmentStart.split('-');
      final year = int.tryParse(parts.isNotEmpty ? parts[0] : '');
      final month = int.tryParse(parts.length > 1 ? parts[1] : '');
      final curParts = monthYear.split('-');
      final cy = int.tryParse(curParts.isNotEmpty ? curParts[0] : '');
      final cm = int.tryParse(curParts.length > 1 ? curParts[1] : '');
      if (year == null || month == null || cy == null || cm == null) return;
      final startIndex = year * 12 + (month - 1);
      final curIndex = cy * 12 + (cm - 1);
      if (curIndex >= startIndex + installmentTotal) return;

      final rawPaid = data['paidInstallmentMonths'];
      final paid = <String, bool>{};
      if (rawPaid is Map) {
        for (final e in rawPaid.entries) {
          paid[e.key.toString()] = e.value == true;
        }
      }
      paid[monthYear] = isPaid;

      final paidCount = paid.values.where((v) => v == true).length;
      final status = data['status']?.toString() ?? DebtStatus.active;
      final nextStatus = (paidCount >= installmentTotal)
          ? DebtStatus.paid
          : (status == DebtStatus.negotiating
              ? DebtStatus.negotiating
              : DebtStatus.active);

      tx.set(
        ref,
        {
          'paidInstallmentMonths': paid,
          'status': nextStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  static Stream<InvestmentProfile?> watchInvestmentProfile(String uid) {
    return _investmentProfile(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return InvestmentProfile.fromJson(data);
    });
  }

  static Stream<InvestmentPlanDoc?> watchInvestmentPlan(String uid) {
    return _investmentPlan(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return InvestmentPlanDoc.fromJson(data);
    });
  }

  static Future<void> saveInvestmentProfileLocal({
    required String uid,
    required String risk,
    required Map<String, double> allocation,
    required List<int> answers,
    String source = 'local',
    String? createdAtIso,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    await _investmentProfile(uid).set(
      {
        'schemaVersion': 1,
        'risk': risk,
        'allocation': allocation,
        'source': source,
        'answers': answers,
        'lastAnswers': answers,
        'lastAnswersAt': nowIso,
        'updatedAt': nowIso,
        'createdAt': createdAtIso ?? nowIso,
        'createdBy': uid,
        'sourceApp': SourceApp.flutter,
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> saveInvestmentProfileAnswers({
    required String uid,
    required List<int> answers,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    await _investmentProfile(uid).set(
      {
        'answers': answers,
        'lastAnswers': answers,
        'lastAnswersAt': nowIso,
        'updatedAt': nowIso,
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> saveInvestmentPlanTargets({
    required String uid,
    required String monthYear,
    required int? emergencyMonthsTarget,
    required double? monthlyContributionTarget,
    required String? risk,
    String? createdAtIso,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    await _investmentPlan(uid).set(
      {
        'schemaVersion': 1,
        'monthYear': monthYear,
        'emergencyMonthsTarget': emergencyMonthsTarget,
        'monthlyContributionTarget': monthlyContributionTarget,
        'risk': risk,
        'updatedAt': nowIso,
        'createdAt': createdAtIso ?? nowIso,
        'createdBy': uid,
        'sourceApp': SourceApp.flutter,
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> saveInvestmentPlanAllocationChoice({
    required String uid,
    required String monthYear,
    required String? risk,
    required double selectedMonthlyAmount,
    required InvestmentPlanSelectedAllocation selectedAllocation,
    String? createdAtIso,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    await _investmentPlan(uid).set(
      {
        'schemaVersion': 1,
        'monthYear': monthYear,
        'risk': risk,
        'selectedMonthlyAmount': selectedMonthlyAmount,
        'selectedAllocation': selectedAllocation.toJson(),
        'selectedAt': nowIso,
        'updatedAt': nowIso,
        'createdAt': createdAtIso ?? nowIso,
        'createdBy': uid,
        'sourceApp': SourceApp.flutter,
      },
      SetOptions(merge: true),
    );
  }

  static Future<bool> hasDebtPlanForMonth(String uid, String monthYear) async {
    final v2 = _debtPlans(uid).doc(monthYear).get();
    final avalanche = _debtPlans(uid).doc('${monthYear}_avalanche').get();
    final snowball = _debtPlans(uid).doc('${monthYear}_snowball').get();
    final snaps = await Future.wait([v2, avalanche, snowball]);
    return snaps.any((s) => s.exists);
  }

  static Stream<DebtPlanDocV2?> watchDebtPlanV2(
    String uid,
    String monthYear,
  ) {
    return _debtPlans(uid).doc(monthYear).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return DebtPlanDocV2.fromJson(data, referenceMonth: snap.id);
    });
  }

  static Future<void> saveDebtPlanV2({
    required String uid,
    required String monthYear,
    required String method,
    required double monthlyBudget,
    required DebtPlanCompactV2 plan,
  }) async {
    final ref = _debtPlans(uid).doc(monthYear);
    final snap = await ref.get();
    final prev = snap.exists ? snap.data() : null;

    await ref.set(
      {
        'schemaVersion': 2,
        'referenceMonth': monthYear,
        'lastMethod': method,
        'methods.$method.monthlyBudget': monthlyBudget,
        'methods.$method.plan': plan.toJson(),
        'methods.$method.updatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
        'sourceApp': SourceApp.flutter,
        if (prev != null && prev.containsKey('createdAt'))
          'createdAt': prev['createdAt']
        else
          'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // --- HABITS (Daily) ---
  static DocumentReference<Map<String, dynamic>> _habitsDoc(String uid) {
    return _userDoc(uid).collection('habits').doc('state');
  }

  static Stream<Map<String, dynamic>?> watchHabitsState(String uid) {
    return _habitsDoc(uid)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  static Future<void> saveHabitsState(
      String uid, Map<String, dynamic> data) async {
    await _habitsDoc(uid).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> saveIncome(String uid, IncomeSource income) async {
    final ref = _incomes(uid).doc(income.id.isEmpty ? null : income.id);
    await ref.set(income.toJson(), SetOptions(merge: true));
  }

  static Future<void> deleteIncome(String uid, String incomeId) async {
    await _incomes(uid).doc(incomeId).delete();
  }

  static Future<void> excludeIncomeMonth(
    String uid,
    String incomeId,
    String monthKey,
  ) async {
    await _incomes(uid).doc(incomeId).set({
      'excludedMonths': FieldValue.arrayUnion([monthKey]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> setIncomeActiveUntil(
    String uid,
    String incomeId,
    String monthKey,
  ) async {
    await _incomes(uid).doc(incomeId).set({
      'activeUntil': monthKey,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static CollectionReference<Map<String, dynamic>> _legacyDashboards(
      String email) {
    return _legacyUserDoc(email).collection('dashboards');
  }

  static CollectionReference<Map<String, dynamic>> _legacyGoals(String email) {
    return _legacyUserDoc(email).collection('goals');
  }

  static Future<bool?> userExists(String email) async {
    try {
      final normalized = email.trim().toLowerCase();
      final snapshot = await _db
          .collection('users')
          .where('email', isEqualTo: normalized)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } on FirebaseException {
      return null;
    }
  }

  static Future<UserProfile?> getUserByUid(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return UserProfile.fromJson(data);
    } on FirebaseException {
      return null;
    }
  }

  static Stream<UserProfile?> watchUserByUid(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return UserProfile.fromJson(data);
    }).handleError((_) {
      // ignore stream errors to avoid tearing down listeners
    });
  }

  static Stream<UserProfile?> watchUserByLegacyEmailDoc(String email) {
    return _legacyUserDoc(email).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return UserProfile.fromJson(data);
    }).handleError((_) {
      // ignore stream errors to avoid tearing down listeners
    });
  }

  static Future<UserProfile?> getUserByLegacyEmailDoc(String email) async {
    try {
      final doc = await _legacyUserDoc(email).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return UserProfile.fromJson(data);
    } on FirebaseException {
      return null;
    }
  }

  static Future<UserProfile?> getCurrentUser() async {
    final uid = _currentUid();
    if (uid == null) return null;
    return getUserByUid(uid);
  }

  static Future<bool> upsertUser(UserProfile user) async {
    final uid = _currentUid();
    if (uid == null) return false;
    try {
      final ref = _userDoc(uid);
      final existingSnap = await ref.get();
      final existing = existingSnap.data();

      final data = user.toJson()..remove('password');
      // Do not let the client override admin-managed fields.
      const blockedFields = [
        'isPremium',
        'premium',
        'premiumAtivo',
        'plan',
        'status',
        'blocked',
        'suspenso',
        'active',
        'admin',
        'isAdmin',
        'role',
      ];
      for (final field in blockedFields) {
        data.remove(field);
      }

      // Preserve server-created timestamp if it already exists (avoid breaking report history windows).
      if (existing != null &&
          existing.containsKey('createdAt') &&
          existing['createdAt'] != null) {
        data['createdAt'] = existing['createdAt'];
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await ref.set(data, SetOptions(merge: true));
      return true;
    } on FirebaseException {
      return false;
    }
  }

  static Future<void> renameUserEmail(String oldEmail, String newEmail) async {
    final uid = _currentUid();
    if (uid == null) return;
    try {
      await _userDoc(uid).set(
        {'email': newEmail.trim().toLowerCase()},
        SetOptions(merge: true),
      );
    } on FirebaseException {
      // ignore to avoid crashing UI when permissions are not ready
    }
  }

  static Future<List<MonthlyDashboard>> getDashboards(String uid) async {
    try {
      final snapshot = await _dashboards(uid).get();
      return snapshot.docs
          .map((d) => MonthlyDashboard.fromJson(d.data(), id: d.id))
          .toList();
    } on FirebaseException {
      return [];
    }
  }

  static Stream<List<MonthlyDashboard>> watchDashboards(String uid) {
    return _dashboards(uid).snapshots().map((snapshot) {
      final dashboards = <MonthlyDashboard>[];
      for (final doc in snapshot.docs) {
        try {
          dashboards.add(MonthlyDashboard.fromJson(doc.data(), id: doc.id));
        } catch (e) {
          debugPrint('FirestoreService: Error parsing dashboard ${doc.id}: $e');
        }
      }
      return dashboards;
    }).handleError((e) {
      debugPrint('FirestoreService: Dashboards stream error: $e');
      return <MonthlyDashboard>[];
    });
  }

  static Future<List<MonthlyDashboard>> getLegacyDashboards(
      String email) async {
    try {
      final snapshot = await _legacyDashboards(email).get();
      return snapshot.docs
          .map((d) => MonthlyDashboard.fromJson(d.data(), id: d.id))
          .toList();
    } on FirebaseException {
      return [];
    }
  }

  static Future<bool> replaceDashboards(
    String uid,
    List<MonthlyDashboard> dashboards,
  ) async {
    try {
      // Deletion logic removed to ensure cross-device sync safety.
      // We only upsert what we have locally.
      final batch = _db.batch();
      for (final d in dashboards) {
        final id = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        final ref = _dashboards(uid).doc(id);
        final data = d.toJson();
        data['expenses'] = const [];
        batch.set(ref, data, SetOptions(merge: true));
      }
      if (dashboards.isNotEmpty) {
        await batch.commit();
      }
      return true;
    } on FirebaseException {
      return false;
    }
  }

  /// Updates both User Profile and the specific Monthly Dashboard atomically.
  /// This ensures that the Web app sees a consistent state immediately.
  static Future<bool> updateIncomeSync({
    required String uid,
    required String monthYear, // Format: YYYY-MM
    required double income,
  }) async {
    try {
      final batch = _db.batch();

      final userRef = _db.collection('users').doc(uid);
      final dashboardRef = _dashboards(uid).doc(monthYear);

      batch.update(userRef, {
        'monthlyIncome': income,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(
          dashboardRef,
          {
            'salary': income,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      await batch.commit();
      return true;
    } on FirebaseException catch (e) {
      debugPrint('FirestoreService: updateIncomeSync error: $e');
      return false;
    }
  }

  /// Web parity: sync user monthlyIncome (fixed baseline) + dashboard salary (month total)
  /// based on the current incomes list.
  static Future<bool> updateUserIncomeSync({
    required String uid,
    required String monthYear, // Format: YYYY-MM
    required List<IncomeSource> incomes,
  }) async {
    bool isIncomeActiveForMonth(IncomeSource income, String monthKey) {
      if (!income.isActive) return false;
      if (income.excludedMonths.contains(monthKey)) return false;
      if (income.activeFrom != null &&
          monthKey.compareTo(income.activeFrom!) < 0) {
        return false;
      }
      if (income.activeUntil != null &&
          monthKey.compareTo(income.activeUntil!) > 0) {
        return false;
      }
      return true;
    }

    double fixedBaseline = 0.0;
    double monthTotal = 0.0;

    for (final income in incomes) {
      final type = (income.type.isEmpty ? 'fixed' : income.type);
      if (income.isActive && type == 'fixed') {
        fixedBaseline += income.amount;
      }
      if (isIncomeActiveForMonth(income, monthYear)) {
        monthTotal += income.amount;
      }
    }

    try {
      final batch = _db.batch();
      final userRef = _db.collection('users').doc(uid);
      final dashboardRef = _dashboards(uid).doc(monthYear);

      batch.update(userRef, {
        'monthlyIncome': fixedBaseline,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(
        dashboardRef,
        {
          'salary': monthTotal,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      return true;
    } on FirebaseException catch (e) {
      debugPrint('FirestoreService: updateUserIncomeSync error: $e');
      return false;
    }
  }

  static Future<bool> upsertDashboard(
      String uid, MonthlyDashboard dashboard) async {
    try {
      final id =
          '${dashboard.year}-${dashboard.month.toString().padLeft(2, '0')}';
      final data = dashboard.toJson();
      data['expenses'] = const [];
      await _dashboards(uid).doc(id).set(data, SetOptions(merge: true));
      return true;
    } on FirebaseException {
      return false;
    }
  }

  static Future<bool> upsertLegacyDashboard(
      String email, MonthlyDashboard dashboard) async {
    try {
      final id =
          '${dashboard.year}-${dashboard.month.toString().padLeft(2, '0')}';
      final data = dashboard.toJson();
      data['expenses'] = const [];
      await _legacyDashboards(email).doc(id).set(data);
      return true;
    } on FirebaseException {
      return false;
    }
  }

  static Future<List<Goal>> getGoals(String uid) async {
    try {
      final snapshot = await _goals(uid).get();
      return snapshot.docs.map((d) => Goal.fromJson(d.data())).toList();
    } on FirebaseException {
      return [];
    }
  }

  static Future<List<Goal>> getLegacyGoals(String email) async {
    try {
      final snapshot = await _legacyGoals(email).get();
      return snapshot.docs.map((d) => Goal.fromJson(d.data())).toList();
    } on FirebaseException {
      return [];
    }
  }

  static Future<bool> replaceGoals(String uid, List<Goal> goals) async {
    try {
      if (goals.isEmpty) return true;

      final batch = _db.batch();
      for (final g in goals) {
        final ref = _goals(uid).doc(g.id);
        batch.set(ref, g.toJson());
      }
      await batch.commit();
      return true;
    } on FirebaseException {
      return false;
    }
  }

  static Stream<List<Goal>> watchGoals(String uid) {
    return _goals(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((d) => Goal.fromJson(d.data())).toList();
    }).handleError((_) {
      return <Goal>[];
    });
  }

  static Future<bool> addGoal(String uid, Goal goal, {String? customId}) async {
    try {
      final id = customId ?? goal.id;
      final data = goal.toJson();
      data['id'] = id;
      await _goals(uid).doc(id).set(data);

      // Port from Web FirestoreService.js: addGoal adds 50 XP
      await addXp(uid, 50, null);

      return true;
    } on FirebaseException {
      return false;
    }
  }

  static Future<bool> toggleChallenge(
      String uid, String challengeId, bool isCompleted) async {
    try {
      await _goals(uid).doc(challengeId).update({
        'completed': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (isCompleted) {
        // Port from Web FirestoreService.js: toggleChallenge adds 25 XP
        await addXp(uid, 25, null);
      }
      return true;
    } on FirebaseException {
      return false;
    }
  }

  static Future<bool> updateGoal(String uid, Goal goal) async {
    try {
      await _goals(uid).doc(goal.id).update(goal.toJson());
      return true;
    } on FirebaseException {
      return false;
    }
  }

  static Future<bool> toggleGoal(
      String uid, String goalId, bool completed) async {
    try {
      await _goals(uid).doc(goalId).update({'completed': completed});
      return true;
    } on FirebaseException {
      return false;
    }
  }

  static Future<bool> deleteGoal(String uid, String goalId) async {
    try {
      await _goals(uid).doc(goalId).delete();
      return true;
    } on FirebaseException {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getMissions() async {
    final snapshot = await _db.collection('missions').get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  static Future<bool> addXp(
    String uid,
    int amount,
    String? missionId, {
    String? note,
    String? completionType,
  }) async {
    try {
      final updates = <String, dynamic>{
        'totalXp': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (missionId != null) {
        updates['completedMissions'] = FieldValue.arrayUnion([missionId]);
        if (note != null && note.trim().isNotEmpty) {
          updates['missionNotes.$missionId'] = note.trim();
        }
        if (completionType != null && completionType.trim().isNotEmpty) {
          updates['missionCompletionType.$missionId'] = completionType.trim();
        }
      }
      await _userDoc(uid).update(updates);
      return true;
    } on FirebaseException {
      return false;
    }
  }

  static Future<void> _deleteSubcollection(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    try {
      final snapshot = await ref.get();
      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException {
      // ignore to avoid crashing UI when permissions are not ready
    }
  }

  static Future<void> logEngagementEvent({
    required String uid,
    required String type,
    Map<String, dynamic>? payload,
  }) async {
    if (uid.trim().isEmpty || type.trim().isEmpty) return;
    try {
      await _userDoc(uid).collection('engagementEvents').add({
        'type': type.trim(),
        'payload': payload ?? const <String, dynamic>{},
        'sourceApp': SourceApp.flutter,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      // ignore to avoid UI impact on best-effort analytics
    }
  }

  // --- TRANSACTIONS (Real-time Sync) ---
  static CollectionReference<Map<String, dynamic>> _transactions(String uid) {
    return _userDoc(uid).collection('transactions');
  }

  static Stream<List<Expense>> watchTransactions(
    String uid,
    String monthYear, {
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    List<String>? categoryKeys,
    String? status,
  }) {
    Query<Map<String, dynamic>> q = _transactions(uid);

    DateTime? resolvedFrom = dueDateFrom;
    DateTime? resolvedTo = dueDateTo;
    if (resolvedFrom == null && resolvedTo == null && monthYear.isNotEmpty) {
      final parts = monthYear.split('-');
      if (parts.length == 2) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year != null && month != null && month >= 1 && month <= 12) {
          resolvedFrom = DateTime(year, month, 1, 0, 0, 0);
          resolvedTo = DateTime(year, month + 1, 0, 23, 59, 59, 999);
        }
      }
    }

    final keys = categoryKeys == null
        ? const <String>[]
        : categoryKeys.where((k) => k.trim().isNotEmpty).toSet().toList();
    if (keys.length == 1) {
      q = q.where('categoryKey', isEqualTo: keys.first);
    } else if (keys.length > 1) {
      q = q.where('categoryKey', whereIn: keys.take(10).toList());
    }

    if (status != null && status.isNotEmpty) {
      q = q.where('status', isEqualTo: status);
    }

    if (resolvedFrom != null) {
      q = q.where('dueDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(resolvedFrom));
    }
    if (resolvedTo != null) {
      q = q.where('dueDate',
          isLessThanOrEqualTo: Timestamp.fromDate(resolvedTo));
    }

    q = q.orderBy('dueDate', descending: true);

    return q.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Expense.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();
    });
  }

  static Future<void> backfillDueDatesForMonth(
    String uid,
    String monthYear, {
    int limitDocs = 250,
  }) async {
    try {
      final parts = monthYear.split('-');
      if (parts.length != 2) return;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year == null || month == null || month < 1 || month > 12) return;

      final startDate = DateTime(year, month, 1, 0, 0, 0);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59, 999);

      final snap = await _transactions(uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .limit(limitDocs)
          .get();

      final batch = _db.batch();
      var pending = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data.containsKey('dueDate') && data['dueDate'] != null) continue;
        final dateValue = data['date'];
        if (dateValue is! Timestamp) continue;
        batch.set(
            doc.reference,
            {'dueDate': dateValue, 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
        pending += 1;
        if (pending >= 450) break;
      }

      if (pending > 0) {
        await batch.commit();
      }
    } catch (_) {
      // ignore: best-effort backfill to avoid empty reports when legacy docs miss dueDate
    }
  }

  static Future<void> backfillSeriesIdsForMonth(
    String uid,
    String monthYear, {
    int limitDocs = 250,
  }) async {
    try {
      final parts = monthYear.split('-');
      if (parts.length != 2) return;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year == null || month == null || month < 1 || month > 12) return;

      final startDate = DateTime(year, month, 1, 0, 0, 0);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59, 999);

      final snap = await _transactions(uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .limit(limitDocs)
          .get();

      final batch = _db.batch();
      var pending = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final rawSeries = data['seriesId']?.toString();
        if (rawSeries != null && rawSeries.trim().isNotEmpty) continue;

        final typeUpper = (data['type']?.toString() ?? '').toUpperCase();
        final isFixedV2 = typeUpper == 'DEBT_PAYMENT' ||
            (typeUpper == 'EXPENSE' && data['isVariable'] != true);
        if (!isFixedV2) continue;

        final debtId = data['debtId']?.toString().trim();
        String? nextSeriesId;
        if (debtId != null && debtId.isNotEmpty) {
          nextSeriesId = debtSeriesIdFor(debtId);
        } else {
          final name = data['name']?.toString() ?? '';
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          final dueDay = (data['dueDay'] as num?)?.toInt();
          final categoryRaw = data['category']?.toString();
          final categoryKeyRaw = data['categoryKey']?.toString();
          final isCreditCard = data['isCreditCard'] == true;
          final creditCardId = data['creditCardId']?.toString();

          final sig = [
            _normalizeSeriesName(name),
            (amount.isFinite ? amount : 0.0).toStringAsFixed(2),
            _normalizeSeriesName(
                (categoryRaw != null && categoryRaw.trim().isNotEmpty)
                    ? categoryRaw
                    : (categoryKeyRaw ?? '')),
            ((dueDay != null && dueDay > 0) ? dueDay : 0).toString(),
            isCreditCard ? 'cc' : 'no',
            creditCardId ?? '',
          ].join('|');
          if (sig != '||0|no|') {
            nextSeriesId = 'fix_${_toBase36(_djb2Hash(sig))}';
          }
        }

        if (nextSeriesId == null || nextSeriesId.trim().isEmpty) continue;
        batch.set(
          doc.reference,
          {
            'seriesId': nextSeriesId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        pending += 1;
        if (pending >= 450) break;
      }

      if (pending > 0) {
        await batch.commit();
      }
    } catch (_) {
      // ignore: best-effort backfill to make fixed/debt transactions deletable
    }
  }

  static Future<void> saveTransaction(String uid, Expense expense) async {
    final ref = expense.id.isEmpty
        ? _transactions(uid).doc()
        : _transactions(uid).doc(expense.id);

    // Check if exists to preserve createdAt
    final docSnap = await ref.get();
    final exists = docSnap.exists;
    final existingData = exists ? docSnap.data() : null;

    final data = expense.toJson();

    // Ensure a stable seriesId for fixed transactions (prevents "zombie" fixed launches).
    final hasInstallments = (expense.installments ?? 0) > 1;
    final rawSeriesId = (expense.seriesId ?? '').trim();
    if (!hasInstallments && rawSeriesId.isEmpty) {
      final debtId = (expense.debtId ?? '').trim();
      if (debtId.isNotEmpty) {
        data['seriesId'] = debtSeriesIdFor(debtId);
      } else if (expense.isFixed) {
        final computed = fixedSeriesIdForExpense(expense);
        if (computed != null && computed.isNotEmpty) {
          data['seriesId'] = computed;
        }
      }
    }

    // Standardize: use Firestore Timestamp
    data['date'] = Timestamp.fromDate(expense.date);
    data['dueDate'] = Timestamp.fromDate(expense.date);
    data['referenceMonth'] = toReferenceMonth(expense.date) ??
        '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
    data['categoryKey'] = toCategoryKey(expense.category.name) ?? 'OUTROS';
    data['schemaVersion'] = SchemaVersion.v2;
    data['sourceApp'] = SourceApp.flutter;
    data['createdBy'] = uid;
    final resolvedTxType =
        (expense.txType != null && expense.txType!.isNotEmpty)
            ? expense.txType!.toUpperCase()
            : ((expense.debtId != null && expense.debtId!.isNotEmpty) ||
                    expense.category == ExpenseCategory.dividas)
                ? TxType.debtPayment
                : (expense.isInvestment ? TxType.investment : TxType.expense);

    data['type'] = resolvedTxType;
    data['status'] = expense.isPaid ? TxStatus.paid : TxStatus.pending;
    data['paidAt'] = expense.isPaid ? Timestamp.fromDate(DateTime.now()) : null;
    data['isVariable'] = expense.isInvestment ? false : expense.isVariable;
    data['amount'] = expense.amount.toDouble(); // Ensure double
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (exists &&
        existingData != null &&
        existingData.containsKey('createdAt')) {
      data['createdAt'] = existingData['createdAt'];
    } else {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(data, SetOptions(merge: true));
  }

  static Future<void> deleteTransaction(
      String uid, String transactionId) async {
    if (transactionId.trim().isEmpty) return;
    await _transactions(uid).doc(transactionId).delete();
  }
}
