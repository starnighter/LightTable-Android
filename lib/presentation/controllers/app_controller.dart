import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/course.dart';
import '../../domain/models/period.dart';
import '../../domain/models/schedule.dart';
import '../../domain/repositories/period_repository.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/services/schedule_import_parser.dart';
import '../../platform/widget_refresh_service.dart';

typedef WidgetRefresher = Future<void> Function();

final class AppController extends ChangeNotifier {
  AppController(
    this._scheduleRepository,
    this._periodRepository, {
    WidgetRefresher? refreshWidgets,
  }) : _refreshWidgets = refreshWidgets ?? WidgetRefreshService.refresh;

  final ScheduleRepository _scheduleRepository;
  final PeriodRepository _periodRepository;
  final WidgetRefresher _refreshWidgets;

  bool _isLoading = true;
  Object? _loadError;
  List<Schedule> _schedules = const [];
  Schedule? _selectedSchedule;
  List<Course> _courses = const [];
  List<Period> _periods = const [];

  bool get isLoading => _isLoading;
  Object? get loadError => _loadError;
  List<Schedule> get schedules => _schedules;
  Schedule? get selectedSchedule => _selectedSchedule;
  List<Course> get courses => _courses;
  List<Period> get periods => _periods;

  Future<void> load() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      await _refreshData();
    } catch (error) {
      _loadError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    if (_loadError == null) _requestWidgetRefresh();
  }

  Future<void> refresh() async {
    await _refreshData();
    notifyListeners();
  }

  Future<void> selectSchedule(String scheduleId) async {
    await _scheduleRepository.selectSchedule(scheduleId);
    await _refreshAfterMutation();
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _scheduleRepository.deleteSchedule(scheduleId);
    await _refreshAfterMutation();
  }

  Future<void> updateSchedule(Schedule schedule) async {
    await _scheduleRepository.updateSchedule(schedule);
    await _refreshAfterMutation();
  }

  Future<void> updateCourse(Course course) async {
    await _scheduleRepository.updateCourse(course);
    await _refreshAfterMutation();
  }

  Future<void> updatePeriod(Period period) async {
    await _periodRepository.updatePeriod(period);
    await _refreshAfterMutation();
  }

  Future<void> addPeriod() async {
    await _periodRepository.addPeriod();
    await _refreshAfterMutation();
  }

  Future<void> deleteLastPeriod() async {
    await _periodRepository.deleteLastPeriod();
    await _refreshAfterMutation();
  }

  Future<Schedule> importScheduleResult(String rawData) async {
    final import = ScheduleImportParser.parse(
      rawData,
      allowedPeriodNumbers: _periods.map((period) => period.number).toSet(),
    );
    final schedule = await _scheduleRepository.importSchedule(import);
    await _refreshAfterMutation();
    return schedule;
  }

  Future<void> _refreshAfterMutation() async {
    await refresh();
    _requestWidgetRefresh();
  }

  void _requestWidgetRefresh() => unawaited(_refreshWidgets());

  Future<void> _refreshData() async {
    final (schedules, selectedId, periods) = await (
      _scheduleRepository.getSchedules(),
      _scheduleRepository.getSelectedScheduleId(),
      _periodRepository.getPeriods(),
    ).wait;
    final selected = selectedId == null
        ? null
        : schedules.cast<Schedule?>().firstWhere(
            (schedule) => schedule?.id == selectedId,
            orElse: () => null,
          );
    final courses = selected == null
        ? const <Course>[]
        : await _scheduleRepository.getCourses(selected.id);
    _schedules = List.unmodifiable(schedules);
    _selectedSchedule = selected;
    _periods = List.unmodifiable(periods);
    _courses = List.unmodifiable(courses);
    _loadError = null;
  }
}
