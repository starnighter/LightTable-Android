import 'package:flutter/material.dart';

import '../../../domain/models/school_source.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/app_controller.dart';
import 'portal_import_page.dart';

class ScheduleImportPage extends StatelessWidget {
  const ScheduleImportPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.selectSchool)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: Column(
              children: [
                for (final school in SchoolSources.supported)
                  ListTile(
                    key: Key('school-${school.shortName}'),
                    leading: const CircleAvatar(
                      child: Icon(Icons.school_outlined),
                    ),
                    title: Text(school.name),
                    subtitle: Text(school.portalUrl),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PortalImportPage(
                          controller: controller,
                          source: school,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.supportedSchoolHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
