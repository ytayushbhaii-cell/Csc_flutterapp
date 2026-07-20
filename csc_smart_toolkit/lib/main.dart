import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/history_provider.dart';
import 'providers/search_provider.dart';
import 'providers/settings_provider.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Warm up the SQLite database on startup to avoid first-use delay.
  // Errors are caught so a DB failure never prevents the app from launching.
  try {
    await DatabaseService.db;
  } catch (_) {}

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const CscSmartToolkitApp(),
    ),
  );
}

class CscSmartToolkitApp extends StatelessWidget {
  const CscSmartToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'CSC Smart Toolkit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      routerConfig: appRouter,
    );
  }
}
