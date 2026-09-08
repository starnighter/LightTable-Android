import 'package:flutter/material.dart';

import '../../domain/models/course.dart';
import '../../domain/models/period.dart';
import '../../domain/models/schedule.dart';
import '../../domain/utils/schedule_date_utils.dart';
import '../../l10n/generated/app_localizations.dart';
import '../utils/ui_formatters.dart';

typedef CourseDraftSaver = Future<void> Function(CourseDraft draft);

class CourseEditorSheet extends StatefulWidget {
  const CourseEditorSheet({
    required this.schedule,
    required this.initialWeek,
    required this.initialWeekday,
    required this.initialPeriod,
    required this.periods,
    required this.onSave,
    this.course,
    super.key,
  });

  final Course? course;
  final Schedule schedule;
  final int initialWeek;
  final int initialWeekday;
  final int initialPeriod;
  final List<Period> periods;
  final CourseDraftSaver onSave;

  static Future<void> show(
    BuildContext context, {
    Course? course,
    required Schedule schedule,
    required int initialWeek,
    required int initialWeekday,
    required int initialPeriod,
    required List<Period> periods,
    required CourseDraftSaver onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CourseEditorSheet(
        course: course,
        schedule: schedule,
        initialWeek: initialWeek,
        initialWeekday: initialWeekday,
        initialPeriod: initialPeriod,
        periods: periods,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CourseEditorSheet> createState() => _CourseEditorSheetState();
}

class _CourseEditorSheetState extends State<CourseEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _teacherController;
  late final TextEditingController _locationController;
  late DateTime _selectedDate;
  late int _startPeriod;
  late int _endPeriod;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final course = widget.course;
    _nameController = TextEditingController(text: course?.name ?? '');
    _teacherController = TextEditingController(text: course?.teacher ?? '');
    _locationController = TextEditingController(text: course?.location ?? '');
    _selectedDate = ScheduleDateUtils.dateFor(
      schedule: widget.schedule,
      week: widget.initialWeek,
      weekday: widget.initialWeekday,
    );
    _startPeriod = course?.firstPeriod ?? widget.initialPeriod;
    _endPeriod = course?.lastPeriod ?? widget.initialPeriod;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.course == null
                      ? strings.addCourse
                      : strings.editCourse,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('course-name-field'),
                  controller: _nameController,
                  decoration: InputDecoration(labelText: strings.courseName),
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? strings.requiredField
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('course-teacher-field'),
                  controller: _teacherController,
                  decoration: InputDecoration(labelText: strings.teacher),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('course-location-field'),
                  controller: _locationController,
                  decoration: InputDecoration(labelText: strings.location),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                InkWell(
                  key: const Key('course-date-picker'),
                  borderRadius: BorderRadius.circular(4),
                  onTap: _saving ? null : _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: strings.courseDate,
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(_dateLabel(strings)),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  strings.classTime,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: const Key('course-start-period'),
                        initialValue: _startPeriod,
                        decoration: InputDecoration(
                          labelText: strings.startTime,
                        ),
                        items: widget.periods
                            .map(
                              (period) => DropdownMenuItem(
                                value: period.number,
                                child: Text(
                                  strings.periodNumber(period.number),
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _startPeriod = value;
                            if (_endPeriod < value) _endPeriod = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('course-end-period-$_startPeriod'),
                        initialValue: _endPeriod,
                        decoration: InputDecoration(labelText: strings.endTime),
                        items: widget.periods
                            .where((period) => period.number >= _startPeriod)
                            .map(
                              (period) => DropdownMenuItem(
                                value: period.number,
                                child: Text(
                                  strings.periodNumber(period.number),
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) setState(() => _endPeriod = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: Text(strings.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const Key('save-course-button'),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(strings.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dateLabel(AppLocalizations strings) {
    final week = ScheduleDateUtils.weekForDate(_selectedDate, widget.schedule)!;
    return strings.courseDateValue(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      week,
    );
  }

  Future<void> _pickDate() async {
    final firstDate = ScheduleDateUtils.dateFor(
      schedule: widget.schedule,
      week: 1,
      weekday: 1,
    );
    final lastDate = ScheduleDateUtils.dateFor(
      schedule: widget.schedule,
      week: widget.schedule.totalWeeks,
      weekday: 7,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final periods = [for (var i = _startPeriod; i <= _endPeriod; i++) i];
      final targetWeek = ScheduleDateUtils.weekForDate(
        _selectedDate,
        widget.schedule,
      )!;
      await widget.onSave(
        CourseDraft(
          name: _nameController.text,
          teacher: _teacherController.text,
          location: _locationController.text,
          weekInterval: [targetWeek],
          weekday: ScheduleDateUtils.iosWeekday(_selectedDate),
          periods: periods,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(UiFormatters.error(error))));
    }
  }
}
