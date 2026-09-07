import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../controllers/app_controller.dart';
import 'home_page.dart';
import 'settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.controller, required this.now, super.key});

  final AppController controller;
  final DateTime Function() now;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  var _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              HomePage(controller: widget.controller, now: widget.now),
              SettingsPage(controller: widget.controller),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: [
              NavigationDestination(
                key: const Key('home-navigation'),
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: strings.home,
              ),
              NavigationDestination(
                key: const Key('settings-navigation'),
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: strings.settings,
              ),
            ],
          ),
        );
      },
    );
  }
}
