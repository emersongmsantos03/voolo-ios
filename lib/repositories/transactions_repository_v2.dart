import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/v2/transaction_v2.dart';
import '../services/audit_fields.dart';

class TransactionsRepositoryV2 {
  TransactionsRepositoryV2(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('transactions');

  Stream<List<TransactionV2>> watch({
    required String uid,
    String? referenceMonth,
    String? categoryKey,
    List<String>? categoryKeys,
    String? status,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
  }) {
    Query<Map<String, dynamic>> q = _col(uid);

    if (referenceMonth != null) {
      q = q.where('referenceMonth', isEqualTo: referenceMonth);
    }
    final keys = categoryKeys == null
        ? const <String>[]
        : categoryKeys.where((k) => k.trim().isNotEmpty).toSet().toList();
    if (keys.length == 1) {
      q = q.where('categoryKey', isEqualTo: keys.first);
    } else if (keys.length > 1) {
      q = q.where('categoryKey', whereIn: keys.take(30).toList());
    } else if (categoryKey != null) {
      q = q.where('categoryKey', isEqualTo: categoryKey);
    }
    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }
    if (dueDateFrom != null) {
      q = q.where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(dueDateFrom));
    }
    if (dueDateTo != null) {
      q = q.where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(dueDateTo));
    }

    q = q.orderBy('dueDate', descending: true);

    return q.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionV2.fromFirestore(doc.data(), id: doc.id);
      }).toList();
    });
  }

  Future<String> upsert({
    required String uid,
    required String sourceApp,
    required TransactionV2 tx,
  }) async {
    final ref = tx.id.isEmpty ? _col(uid).doc() : _col(uid).doc(tx.id);
    final snap = await ref.get();

    final data = tx.toWriteMap(uid: uid, sourceApp: sourceApp);

    if (!snap.exists) {
      await ref.set(
        {
          ...data,
          ...createAuditFields(createdBy: uid, sourceApp: sourceApp),
        },
        SetOptions(merge: true),
      );
    } else {
      await ref.set(
        {
          ...data,
          ...updateAuditFields(),
        },
        SetOptions(merge: true),
      );
    }

    return ref.id;
  }

  Future<void> delete({
    required String uid,
    required String txId,
  }) async {
    await _col(uid).doc(txId).delete();
  }

  Future<void> setStatus({
    required String uid,
    required String txId,
    required String status,
    DateTime? paidAt,
  }) async {
    await _col(uid).doc(txId).update({
      'status': status,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt) : null,
      ...updateAuditFields(),
    });
  }
}
