import 'package:flutter_test/flutter_test.dart';
import 'package:lighttable/data/repositories/sqlite_period_repository.dart';
import 'package:lighttable/data/repositories/sqlite_schedule_repository.dart';
import 'package:lighttable/domain/errors/validation_exception.dart';
import 'package:lighttable/domain/models/course.dart';
import 'package:lighttable/domain/models/period.dart';
import 'package:lighttable/domain/models/schedule_import.dart';

import '../support/test_database.dart';

void main() {
  test('loads defaults and appends a sensible next period', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = SqlitePeriodRepository(database);

    final defaults = await repository.getPeriods();
    expect(defaults, hasLength(10));
    expect(defaults.first.startTime, '08:00');
    expect(defaults.last.endTime, '20:40');

    final added = await repository.addPeriod();
    expect(added.number, 11);
    expect(added.startTime, '20:50');
    expect(added.endTime, '21:35');
  });

  test('rejects overlapping updates without changing stored values', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = SqlitePeriodRepository(database);

    await expectLater(
      repository.updatePeriod(
        Period(number: 2, startMinutes: 500, endMinutes: 550),
      ),
      throwsA(isA<ValidationException>()),
    );
    final periods = await repository.getPeriods();
    expect(periods[1].startTime, '08:55');
  });

  test('prevents deleting a period used by a course', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    var id = 0;
    final scheduleRepository = SqliteScheduleRepository(
      database,
      idGenerator: () => 'id-${id++}',
    );
    final periodRepository = SqlitePeriodRepository(database);
    await scheduleRepository.importSchedule(
      ScheduleImport(
        term: '2025-2026-2',
        courses: [
          CourseDraft(
            name: '晚课',
            weekInterval: const [1],
            weekday: 2,
            periods: const [10],
          ),
        ],
      ),
    );

    await expectLater(
      periodRepository.deleteLastPeriod(),
      throwsA(isA<ValidationException>()),
    );
    expect(await periodRepository.getPeriods(), hasLength(10));
  });

  test(
    'deletes only unused trailing periods and retains at least one',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final repository = SqlitePeriodRepository(database);

      for (var count = 10; count > 1; count--) {
        await repository.deleteLastPeriod();
      }
      expect(await repository.getPeriods(), hasLength(1));
      await expectLater(
        repository.deleteLastPeriod(),
        throwsA(isA<ValidationException>()),
      );
    },
  );
}
