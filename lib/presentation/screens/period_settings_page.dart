import 'package:flutter/material.dart';

import '../../domain/models/period.dart';
import '../../l10n/generated/app_localizations.dart';
import '../controllers/app_controller.dart';
import '../utils/ui_formatters.dart';

class PeriodSettingsPage extends StatelessWidget {
  const PeriodSettingsPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(strings.periodSettings),
          actions: [
            IconButton(
              key: const Key('add-period-button'),
              tooltip: strings.addPeriod,
              onPressed: () => _run(context, controller.addPeriod),
              icon: const Icon(Icons.add),
            ),
            IconButton(
              key: const Key('delete-last-period-button'),
              tooltip: strings.deleteLastPeriod,
              onPressed: controller.periods.length > 1
                  ? () => _run(context, controller.deleteLastPeriod)
                  : null,
              icon: const Icon(Icons.remove),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(strings.periodHint)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final period in controller.periods)
              _PeriodCard(
                key: Key('period-${period.number}'),
                period: period,
                onChanged: (updated) =>
                    _run(context, () => controller.updatePeriod(updated)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(UiFormatters.error(error))));
    }
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.period, required this.onChanged, super.key});

  final Period period;
  final Future<void> Function(Period period) onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(
                '${period.number}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TimeButton(
                    key: Key('period-${period.number}-start'),
                    label: strings.startTime,
                    value: period.startTime,
                    onPressed: () => _pickTime(context, isStart: true),
                  ),
                  _TimeButton(
                    key: Key('period-${period.number}-end'),
                    label: strings.endTime,
                    value: period.endTime,
                    onPressed: () => _pickTime(context, isStart: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, {required bool isStart}) async {
    final minutes = isStart ? period.startMinutes : period.endMinutes;
    final selected = await showTimePicker(
      context: context,
      initialTime: minutes == 1440
          ? const TimeOfDay(hour: 23, minute: 59)
          : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (selected == null) return;
    final updatedMinutes = selected.hour * 60 + selected.minute;
    final updated = isStart
        ? period.copyWith(startMinutes: updatedMinutes)
        : period.copyWith(endMinutes: updatedMinutes);
    await onChanged(updated);
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value),
        ],
      ),
    );
  }
}
