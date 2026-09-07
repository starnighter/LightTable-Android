import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/generated/app_localizations.dart';
import '../presentation/controllers/app_controller.dart';
import '../presentation/screens/main_shell.dart';
import 'app_dependencies.dart';

class LightTableApp extends StatefulWidget {
  const LightTableApp({
    super.key,
    this.dependencies,
    this.now = DateTime.now,
    this.themeMode = ThemeMode.system,
  });

  final AppDependencies? dependencies;
  final DateTime Function() now;
  final ThemeMode themeMode;

  @override
  State<LightTableApp> createState() => _LightTableAppState();
}

class _LightTableAppState extends State<LightTableApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    final dependencies = widget.dependencies ?? AppDependencies.production();
    _controller = AppController(
      dependencies.scheduleRepository,
      dependencies.periodRepository,
    );
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF46636F);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _theme(seedColor, Brightness.light),
      darkTheme: _theme(seedColor, Brightness.dark),
      themeMode: widget.themeMode,
      home: MainShell(controller: _controller, now: widget.now),
    );
  }

  ThemeData _theme(Color seedColor, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
