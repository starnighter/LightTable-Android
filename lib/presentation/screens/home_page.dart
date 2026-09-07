import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../controllers/app_controller.dart';
import '../utils/ui_formatters.dart';
import '../widgets/course_editor_sheet.dart';
import '../widgets/timetable.dart';
import 'import/schedule_import_page.dart';
import 'schedule_management_page.dart';
import 'schedule_settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.controller, required this.now, super.key});

  final AppController controller;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.homeTitle),
        actions: [
          IconButton(
            key: const Key('home-schedule-settings'),
            tooltip: strings.scheduleSettings,
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ScheduleSettingsPage(controller: controller),
              ),
            ),
          ),
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(strings.loadFailed),
              const SizedBox(height: 4),
              Text(
                UiFormatters.error(controller.loadError!),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.load,
                child: Text(strings.retry),
              ),
            ],
          ),
        ),
      );
    }

    final schedule = controller.selectedSchedule;
    if (schedule == null) {
      return _EmptySchedule(controller: controller);
    }
    return Timetable(
      key: ValueKey(schedule.id),
      schedule: schedule,
      courses: controller.courses,
      periods: controller.periods,
      now: now,
      onCourseTap: (course) async {
        await CourseEditorSheet.show(
          context,
          course: course,
          periods: controller.periods,
          onSave: controller.updateCourse,
        );
      },
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: 56,
                color: colors.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              strings.noScheduleTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              strings.noScheduleDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('import-guidance-button'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ScheduleImportPage(controller: controller),
                ),
              ),
              icon: const Icon(Icons.download_outlined),
              label: Text(strings.importSchedule),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ScheduleManagementPage(controller: controller),
                ),
              ),
              child: Text(strings.scheduleManagement),
            ),
          ],
        ),
      ),
    );
  }
}
