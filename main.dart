import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'utils/date_utils.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DateUtilsJetx.init();
  runApp(const JetxApp());
}

class JetxApp extends StatelessWidget {
  const JetxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jetx',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      // ✅ Rotas centralizadas
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.login,
    );
  }
}
