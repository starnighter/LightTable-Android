import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lighttable/data/repositories/sqlite_period_repository.dart';
import 'package:lighttable/data/repositories/sqlite_schedule_repository.dart';
import 'package:lighttable/domain/models/course.dart';
import 'package:lighttable/presentation/controllers/app_controller.dart';

import '../support/test_database.dart';

void main() {
  test('every successful data mutation requests a widget refresh', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final schedules = SqliteScheduleRepository(database);
    var refreshCount = 0;
    final controller = AppController(
      schedules,
      SqlitePeriodRepository(database),
      refreshWidgets: () async => refreshCount++,
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(refreshCount, 1);

    final first = await controller.importScheduleResult(_importResult);
    expect(refreshCount, 2);

    await controller.updateSchedule(first.copyWith(name: '已修改课表'));
    expect(refreshCount, 3);

    await controller.updateCourse(
      controller.courses.single.copyWith(name: '已修改课程'),
    );
    expect(refreshCount, 4);

    await controller.addCourse(
      CourseDraft(
        name: '临时课程',
        weekInterval: const [1],
        weekday: 3,
        periods: const [3],
      ),
    );
    expect(refreshCount, 5);

    final recurring = controller.courses.singleWhere(
      (course) => course.name == '已修改课程',
    );
    await controller.updateCourseOccurrence(
      course: recurring,
      sourceWeek: 1,
      targetWeek: 1,
      targetWeekday: 4,
    );
    expect(refreshCount, 6);

    await controller.updatePeriod(
      controller.periods.first.copyWith(endMinutes: 8 * 60 + 44),
    );
    expect(refreshCount, 7);

    await controller.addPeriod();
    expect(refreshCount, 8);
    await controller.deleteLastPeriod();
    expect(refreshCount, 9);

    final second = await controller.importScheduleResult(_importResult);
    expect(refreshCount, 10);
    await controller.selectSchedule(first.id);
    expect(refreshCount, 11);
    await controller.deleteSchedule(first.id);
    expect(refreshCount, 12);
    expect(controller.selectedSchedule!.id, second.id);
  });
}

final _importResult = jsonEncode({
  'term': '2025-2026-2',
  'courses': [
    {
      'name': '脱敏课程',
      'location': 'A101',
      'teacher': '教师',
      'weekInterval': [1, 2],
      'weekday': 2,
      'period': [1, 2],
      'table': '2025-2026-2',
    },
  ],
});
