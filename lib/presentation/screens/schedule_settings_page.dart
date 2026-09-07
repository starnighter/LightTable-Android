import 'package:flutter/material.dart';

import '../../domain/models/schedule.dart';
import '../../l10n/generated/app_localizations.dart';
import '../controllers/app_controller.dart';
import '../utils/ui_formatters.dart';
import 'period_settings_page.dart';

class ScheduleSettingsPage extends StatefulWidget {
  const ScheduleSettingsPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<ScheduleSettingsPage> createState() => _ScheduleSettingsPageState();
}

class _ScheduleSettingsPageState extends State<ScheduleSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  int? _weeks;
  DateTime? _startDate;
  String? _draftScheduleId;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _setDraft(widget.controller.selectedSchedule);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _setDraft(Schedule? schedule) {
    _draftScheduleId = schedule?.id;
    _nameController.text = schedule?.name ?? '';
    _weeks = schedule?.totalWeeks;
    _startDate = schedule?.startDate;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final selected = widget.controller.selectedSchedule;
        if (_draftScheduleId != selected?.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _setDraft(selected));
          });
        }
        return Scaffold(
          appBar: AppBar(title: Text(strings.scheduleSettings)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey(selected?.id ?? 'none'),
                initialValue: selected?.id,
                decoration: InputDecoration(labelText: strings.currentSchedule),
                hint: Text(strings.selectSchedule),
                items: widget.controller.schedules
                    .map(
                      (schedule) => DropdownMenuItem(
                        value: schedule.id,
                        child: Text(
                          schedule.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (id) async {
                  if (id == null) return;
                  try {
                    await widget.controller.selectSchedule(id);
                    _setDraft(widget.controller.selectedSchedule);
                    if (mounted) setState(() {});
                  } catch (error) {
                    if (context.mounted) _showError(context, error);
                  }
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: selected == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PeriodSettingsPage(controller: widget.controller),
                        ),
                      ),
                icon: const Icon(Icons.schedule_outlined),
                label: Text(strings.periodSettings),
              ),
              const SizedBox(height: 20),
              if (selected == null)
                _NoScheduleMessage(text: strings.noScheduleForSettings)
              else
                Form(
                  key: _formKey,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: const Key('schedule-name-field'),
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: strings.scheduleName,
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? strings.requiredField
                                : null,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            strings.totalWeeks,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Row(
                            children: [
                              IconButton(
                                key: const Key('decrease-weeks'),
                                onPressed: _weeks! > 1
                                    ? () => setState(() => _weeks = _weeks! - 1)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Expanded(
                                child: Text(
                                  strings.totalWeeksValue(_weeks!),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              IconButton(
                                key: const Key('increase-weeks'),
                                onPressed: _weeks! < 52
                                    ? () => setState(() => _weeks = _weeks! + 1)
                                    : null,
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            key: const Key('start-date-picker'),
                            borderRadius: BorderRadius.circular(12),
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: strings.startDate,
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              child: Text(UiFormatters.date(_startDate!)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            key: const Key('save-schedule-button'),
                            onPressed: _saving ? null : () => _save(selected),
                            icon: const Icon(Icons.save_outlined),
                            label: Text(strings.save),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate!,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _startDate = selected);
  }

  Future<void> _save(Schedule schedule) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.controller.updateSchedule(
        schedule.copyWith(
          name: _nameController.text,
          totalWeeks: _weeks,
          startDate: _startDate,
        ),
      );
      _setDraft(widget.controller.selectedSchedule);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saved)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(context, error);
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(UiFormatters.error(error))));
  }
}

class _NoScheduleMessage extends StatelessWidget {
  const _NoScheduleMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.event_busy_outlined, size: 40),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
