import 'package:flutter/material.dart';

import '../../domain/models/schedule.dart';
import '../../l10n/generated/app_localizations.dart';
import '../controllers/app_controller.dart';
import '../utils/ui_formatters.dart';
import 'import/schedule_import_page.dart';

class ScheduleManagementPage extends StatelessWidget {
  const ScheduleManagementPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(strings.scheduleManagement),
          actions: [
            IconButton(
              key: const Key('manage-import-button'),
              tooltip: strings.importSchedule,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ScheduleImportPage(controller: controller),
                ),
              ),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: controller.schedules.isEmpty
            ? Center(child: Text(strings.noSchedules))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: controller.schedules.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final schedule = controller.schedules[index];
                  final isSelected =
                      controller.selectedSchedule?.id == schedule.id;
                  return ListTile(
                    key: Key('schedule-${schedule.id}'),
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(schedule.name),
                    subtitle: Text(
                      '${UiFormatters.date(schedule.startDate)} · '
                      '${strings.totalWeeksValue(schedule.totalWeeks)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Tooltip(
                            message: strings.selected,
                            child: Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        IconButton(
                          key: Key('delete-schedule-${schedule.id}'),
                          tooltip: strings.delete,
                          onPressed: () => _confirmDelete(context, schedule),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    onTap: isSelected
                        ? null
                        : () async {
                            try {
                              await controller.selectSchedule(schedule.id);
                            } catch (error) {
                              if (context.mounted) _showError(context, error);
                            }
                          },
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Schedule schedule) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteScheduleTitle),
        content: Text(strings.deleteScheduleMessage(schedule.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            key: const Key('confirm-delete-schedule'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await controller.deleteSchedule(schedule.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.deleteScheduleDone)));
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(UiFormatters.error(error))));
  }
}
