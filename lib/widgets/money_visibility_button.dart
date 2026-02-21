import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jetx/state/privacy_state.dart';

class MoneyVisibilityButton extends StatelessWidget {
  const MoneyVisibilityButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrivacyState>(
      builder: (context, privacy, _) => IconButton(
        onPressed: privacy.toggle,
        tooltip: privacy.showAmounts ? 'Ocultar valores' : 'Mostrar valores',
        icon: Icon(
          privacy.showAmounts
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
        ),
      ),
    );
  }
}
