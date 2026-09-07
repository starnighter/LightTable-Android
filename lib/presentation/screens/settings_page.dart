import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../controllers/app_controller.dart';
import 'about_page.dart';
import 'period_settings_page.dart';
import 'schedule_management_page.dart';
import 'schedule_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        key: const Key('settings-list'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            key: const Key('settings-schedule-settings'),
            leading: const Icon(Icons.tune),
            title: Text(strings.scheduleSettings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _push(context, ScheduleSettingsPage(controller: controller)),
          ),
          ListTile(
            key: const Key('settings-schedule-management'),
            leading: const Icon(Icons.table_rows_outlined),
            title: Text(strings.scheduleManagement),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _push(context, ScheduleManagementPage(controller: controller)),
          ),
          ListTile(
            key: const Key('settings-period-settings'),
            leading: const Icon(Icons.schedule_outlined),
            title: Text(strings.periodSettings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _push(context, PeriodSettingsPage(controller: controller)),
          ),
          const Divider(height: 24),
          ListTile(
            key: const Key('settings-about'),
            leading: const Icon(Icons.info_outline),
            title: Text(strings.about),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const AboutPage()),
          ),
        ],
      ),
    );
  }

  Future<void> _push(BuildContext context, Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
