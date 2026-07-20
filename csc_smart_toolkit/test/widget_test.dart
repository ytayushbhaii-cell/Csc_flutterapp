import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:csc_smart_toolkit/core/theme/theme_provider.dart';
import 'package:csc_smart_toolkit/core/theme/app_theme.dart';
import 'package:csc_smart_toolkit/providers/favorites_provider.dart';
import 'package:csc_smart_toolkit/providers/history_provider.dart';
import 'package:csc_smart_toolkit/providers/search_provider.dart';
import 'package:csc_smart_toolkit/providers/settings_provider.dart';

Widget _buildTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ChangeNotifierProvider(create: (_) => SearchProvider()),
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: child,
    ),
  );
}

void main() {
  testWidgets('App smoke test — providers mount without crash',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(const Scaffold(body: Center(child: Text('CSC Smart Toolkit')))),
    );
    expect(find.text('CSC Smart Toolkit'), findsOneWidget);
  });

  testWidgets('Light theme applies primary color', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(const Scaffold(body: SizedBox())));
    final context = tester.element(find.byType(Scaffold));
    // Primary blue in light theme
    expect(Theme.of(context).colorScheme.primary,
        const Color(0xFF1D4ED8));
  });

  testWidgets('Dark theme applies dark primary color',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => FavoritesProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).colorScheme.primary,
        const Color(0xFF3B82F6));
  });
}
