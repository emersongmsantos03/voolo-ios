import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:jetx/state/privacy_state.dart';
import 'package:jetx/utils/currency_utils.dart';

class SensitiveDisplay {
  SensitiveDisplay._();

  static const String _maskedMoney = 'R\$ •••••';

  static String money(BuildContext context, double value) {
    final show = context.watch<PrivacyState>().showAmounts;
    return show ? CurrencyUtils.format(value) : _maskedMoney;
  }
}
