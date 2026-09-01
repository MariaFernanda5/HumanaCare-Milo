import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'models/app_state.dart';
import 'router/app_router.dart';

void main() async {
  await initializeDateFormatting('pt_BR', null);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const HumanaCareApp(),
    ),
  );
}

class HumanaCareApp extends StatelessWidget {
  const HumanaCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HumanaCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router(),
    );
  }
}
