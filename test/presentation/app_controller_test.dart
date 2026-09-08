import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lighttable/data/database/light_table_database.dart';
import 'package:lighttable/data/repositories/sqlite_period_repository.dart';
import 'package:lighttable/data/repositories/sqlite_schedule_repository.dart';
import 'package:lighttable/domain/models/course.dart';
import 'package:lighttable/domain/models/period.dart';
import 'package:lighttable/domain/models/schedule.dart';
import 'package:lighttable/domain/models/schedule_import.dart';
import 'package:lighttable/domain/repositories/period_repository.dart';
import 'package:lighttable/domain/repositories/schedule_repository.dart';
import 'package:lighttable/presentation/controllers/app_controller.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test(
    'controller restores selected schedule and edits after database restart',
    () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp(
        'lighttable-controller-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final databasePath = path.join(directory.path, 'lighttable.db');

      final firstDatabase = LightTableDatabase(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      var id = 0;
      final firstSchedules = SqliteScheduleRepository(
        firstDatabase,
        idGenerator: () => 'id-${id++}',
        clock: () => DateTime(2026, 2, 1),
      );
      final imported = await firstSchedules.importSchedule(
        ScheduleImport(
          term: '2025-2026-2',
          courses: [
            CourseDraft(
              name: '高等数学',
              location: 'A101',
              teacher: '王老师',
              weekInterval: const [1, 2],
              weekday: 2,
              periods: const [1, 2],
            ),
          ],
        ),
      );
      await firstSchedules.updateSchedule(imported.copyWith(name: '重启后课表'));
      final course = (await firstSchedules.getCourses(imported.id)).single;
      await firstSchedules.updateCourse(course.copyWith(name: '重启后课程'));
      await firstDatabase.close();

      final reopenedDatabase = LightTableDatabase(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(reopenedDatabase.close);
      final controller = AppController(
        SqliteScheduleRepository(reopenedDatabase),
        SqlitePeriodRepository(reopenedDatabase),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.loadError, isNull);
      expect(controller.selectedSchedule!.name, '重启后课表');
      expect(controller.courses.single.name, '重启后课程');
      expect(controller.periods, hasLength(10));
    },
  );

  test('starts independent startup reads concurrently', () async {
    final schedules = _DeferredScheduleRepository();
    final periods = _DeferredPeriodRepository();
    final controller = AppController(schedules, periods);
    addTearDown(controller.dispose);

    final load = controller.load();

    expect(schedules.getSchedulesCalls, 1);
    expect(schedules.getSelectedScheduleIdCalls, 1);
    expect(periods.getPeriodsCalls, 1);
    expect(schedules.getCoursesCalls, 0);

    final schedule = Schedule(
      id: 'schedule',
      name: '课表',
      totalWeeks: 20,
      startDate: DateTime(2026, 3, 1),
      createdAt: DateTime(2026, 2, 1),
    );
    schedules.schedules.complete([schedule]);
    schedules.selectedId.complete(schedule.id);
    periods.periods.complete([
      Period(number: 1, startMinutes: 480, endMinutes: 525),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(schedules.getCoursesCalls, 1);
    schedules.courses.complete(const []);
    await load;

    expect(controller.selectedSchedule, same(schedule));
    expect(controller.loadError, isNull);
  });
}

final class _DeferredScheduleRepository implements ScheduleRepository {
  final schedules = Completer<List<Schedule>>();
  final selectedId = Completer<String?>();
  final courses = Completer<List<Course>>();

  var getSchedulesCalls = 0;
  var getSelectedScheduleIdCalls = 0;
  var getCoursesCalls = 0;

  @override
  Future<Course> addCourse(String scheduleId, CourseDraft course) =>
      throw UnimplementedError();

  @override
  Future<List<Schedule>> getSchedules() {
    getSchedulesCalls++;
    return schedules.future;
  }

  @override
  Future<String?> getSelectedScheduleId() {
    getSelectedScheduleIdCalls++;
    return selectedId.future;
  }

  @override
  Future<List<Course>> getCourses(String scheduleId) {
    getCoursesCalls++;
    return courses.future;
  }

  @override
  Future<void> deleteSchedule(String scheduleId) => throw UnimplementedError();

  @override
  Future<Schedule?> getSchedule(String id) => throw UnimplementedError();

  @override
  Future<Schedule?> getSelectedSchedule() => throw UnimplementedError();

  @override
  Future<Schedule> importSchedule(ScheduleImport data) =>
      throw UnimplementedError();

  @override
  Future<void> selectSchedule(String? scheduleId) => throw UnimplementedError();

  @override
  Future<void> updateCourse(Course course) => throw UnimplementedError();

  @override
  Future<void> updateCourseOccurrence({
    required Course course,
    required int sourceWeek,
    required int targetWeek,
    required int targetWeekday,
  }) => throw UnimplementedError();

  @override
  Future<void> updateSchedule(Schedule schedule) => throw UnimplementedError();
}

final class _DeferredPeriodRepository implements PeriodRepository {
  final periods = Completer<List<Period>>();
  var getPeriodsCalls = 0;

  @override
  Future<List<Period>> getPeriods() {
    getPeriodsCalls++;
    return periods.future;
  }

  @override
  Future<Period> addPeriod() => throw UnimplementedError();

  @override
  Future<void> deleteLastPeriod() => throw UnimplementedError();

  @override
  Future<void> updatePeriod(Period period) => throw UnimplementedError();
}
