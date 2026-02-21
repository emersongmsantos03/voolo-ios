import 'package:flutter/services.dart';

import '../../utils/money_input.dart';

class MoneyTextInputFormatter extends TextInputFormatter {
  const MoneyTextInputFormatter({this.maxDigits = 12});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.trim();
    if (raw.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > maxDigits) return oldValue;

    final oldDigits = oldValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final atEnd = newValue.selection.baseOffset == newValue.text.length;
    final isAppend = atEnd && digits.length == oldDigits.length + 1;
    final isDelete = atEnd && oldDigits.length == digits.length + 1;

    double value;
    if (isAppend || isDelete) {
      // Progressive input (shift left by cents) for normal typing/backspace.
      value = (int.tryParse(digits) ?? 0) / 100.0;
    } else {
      // If the user pasted/typed a number with a decimal separator, prefer parsing
      // to avoid dropping cents (e.g. "1540.8" -> "1.540,80", not "154,08").
      final hasSeparator = raw.contains('.') || raw.contains(',');
      value = hasSeparator
          ? parseMoneyInput(raw)
          : (int.tryParse(digits) ?? 0) / 100.0;
    }

    final text = formatMoneyInput(value);

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
