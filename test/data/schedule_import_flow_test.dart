import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lighttable/data/repositories/sqlite_period_repository.dart';
import 'package:lighttable/data/repositories/sqlite_schedule_repository.dart';
import 'package:lighttable/presentation/controllers/app_controller.dart';

import '../support/test_database.dart';

void main() {
  String validResult({int courseCount = 1}) => jsonEncode({
    'term': '2025-2026-2',
    'courses': [
      for (var index = 0; index < courseCount; index++)
        {
          'name': '脱敏课程 ${index + 1}',
          'location': '教室 ${index + 1}',
          'teacher': '教师 ${index + 1}',
          'weekInterval': [1, 2],
          'weekday': index + 1,
          'period': [1, 2],
          'table': '2025-2026-2',
        },
    ],
  });

  test(
    'repeated imports create independent schedules and select the latest',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      var id = 0;
      final scheduleRepository = SqliteScheduleRepository(
        database,
        idGenerator: () => 'id-${id++}',
        clock: () => DateTime(2026, 3, 1, 0, id),
      );
      final controller = AppController(
        scheduleRepository,
        SqlitePeriodRepository(database),
      );
      addTearDown(controller.dispose);
      await controller.load();

      final first = await controller.importScheduleResult(validResult());
      final second = await controller.importScheduleResult(validResult());

      expect(controller.schedules, hasLength(2));
      expect(first.id, isNot(second.id));
      expect(controller.selectedSchedule!.id, second.id);
    },
  );

  test('database failure rolls the whole validated import back', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final ids = [
      'schedule-id',
      'duplicate-course',
      'duplicate-course',
    ].iterator;
    final scheduleRepository = SqliteScheduleRepository(
      database,
      idGenerator: () {
        ids.moveNext();
        return ids.current;
      },
    );
    final controller = AppController(
      scheduleRepository,
      SqlitePeriodRepository(database),
    );
    addTearDown(controller.dispose);
    await controller.load();

    await expectLater(
      controller.importScheduleResult(validResult(courseCount: 2)),
      throwsA(anything),
    );

    expect(await scheduleRepository.getSchedules(), isEmpty);
    expect(await scheduleRepository.getSelectedScheduleId(), isNull);
  });

  test('validation failure performs no database writes', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final scheduleRepository = SqliteScheduleRepository(database);
    final controller = AppController(
      scheduleRepository,
      SqlitePeriodRepository(database),
    );
    addTearDown(controller.dispose);
    await controller.load();

    await expectLater(
      controller.importScheduleResult(
        jsonEncode({
          'term': '2025-2026-2',
          'courses': [
            {
              'name': '脱敏课程',
              'location': '',
              'teacher': '',
              'weekInterval': [1],
              'weekday': 2,
              'period': [1, 3],
            },
          ],
        }),
      ),
      throwsA(anything),
    );

    expect(await scheduleRepository.getSchedules(), isEmpty);
    expect(await scheduleRepository.getSelectedScheduleId(), isNull);
  });
}
