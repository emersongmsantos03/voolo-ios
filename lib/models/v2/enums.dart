class SchemaVersion {
  static const int v2 = 2;
}

class SourceApp {
  static const String flutter = 'flutter';
  static const String web = 'web';
  static const String admin = 'admin';
}

class TxType {
  static const String expense = 'EXPENSE';
  static const String income = 'INCOME';
  static const String investment = 'INVESTMENT';
  static const String debtPayment = 'DEBT_PAYMENT';
}

class TxStatus {
  static const String pending = 'PENDING';
  static const String paid = 'PAID';
}

class DebtStatus {
  static const String active = 'ACTIVE';
  static const String negotiating = 'NEGOTIATING';
  static const String paid = 'PAID';
}

class InsightSeverity {
  static const String info = 'INFO';
  static const String warning = 'WARNING';
  static const String critical = 'CRITICAL';
}

