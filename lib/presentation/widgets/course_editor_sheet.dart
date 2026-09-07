import 'package:flutter/material.dart';

import '../../domain/models/course.dart';
import '../../domain/models/period.dart';
import '../../l10n/generated/app_localizations.dart';
import '../utils/ui_formatters.dart';

class CourseEditorSheet extends StatefulWidget {
  const CourseEditorSheet({
    required this.course,
    required this.periods,
    required this.onSave,
    super.key,
  });

  final Course course;
  final List<Period> periods;
  final Future<void> Function(Course course) onSave;

  static Future<void> show(
    BuildContext context, {
    required Course course,
    required List<Period> periods,
    required Future<void> Function(Course course) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          CourseEditorSheet(course: course, periods: periods, onSave: onSave),
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
  late int _startPeriod;
  late int _endPeriod;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course.name);
    _teacherController = TextEditingController(text: widget.course.teacher);
    _locationController = TextEditingController(text: widget.course.location);
    _startPeriod = widget.course.firstPeriod;
    _endPeriod = widget.course.lastPeriod;
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
                  strings.courseName,
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final periods = [for (var i = _startPeriod; i <= _endPeriod; i++) i];
      await widget.onSave(
        widget.course.copyWith(
          name: _nameController.text,
          teacher: _teacherController.text,
          location: _locationController.text,
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
