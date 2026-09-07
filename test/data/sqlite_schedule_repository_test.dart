import 'package:flutter_test/flutter_test.dart';
import 'package:lighttable/data/repositories/sqlite_schedule_repository.dart';
import 'package:lighttable/domain/errors/validation_exception.dart';
import 'package:lighttable/domain/models/course.dart';
import 'package:lighttable/domain/models/schedule_import.dart';

import '../support/test_database.dart';

void main() {
  late int nextId;

  ScheduleImport importData({
    String name = '高等数学',
    List<int> weeks = const [1, 2],
    List<int> periods = const [1, 2],
  }) {
    return ScheduleImport(
      term: '2025-2026-2',
      courses: [
        CourseDraft(
          name: name,
          location: 'A101',
          teacher: '王老师',
          weekInterval: weeks,
          weekday: 2,
          periods: periods,
        ),
      ],
    );
  }

  test('imports a schedule transactionally and selects it', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    nextId = 0;
    final repository = SqliteScheduleRepository(
      database,
      idGenerator: () => 'id-${nextId++}',
      clock: () => DateTime.utc(2026, 3),
    );

    final schedule = await repository.importSchedule(importData());
    final courses = await repository.getCourses(schedule.id);

    expect(schedule.id, 'id-0');
    expect(schedule.name, '2025-2026-2');
    expect(schedule.totalWeeks, 20);
    expect(schedule.startDate, DateTime(2026, 3));
    expect(await repository.getSelectedScheduleId(), schedule.id);
    expect(courses, hasLength(1));
    expect(courses.single.id, 'id-1');
    expect(courses.single.weekInterval, [1, 2]);
    expect(courses.single.periods, [1, 2]);
  });

  test(
    'rolls back every row when a course references a missing period',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      nextId = 0;
      final repository = SqliteScheduleRepository(
        database,
        idGenerator: () => 'id-${nextId++}',
      );

      await expectLater(
        repository.importSchedule(importData(periods: const [10, 11])),
        throwsA(isA<ValidationException>()),
      );
      expect(await repository.getSchedules(), isEmpty);
      expect(await repository.getSelectedScheduleId(), isNull);
    },
  );

  test(
    'deleting the selected schedule falls back then clears selection',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      nextId = 0;
      var clockTick = 0;
      final repository = SqliteScheduleRepository(
        database,
        idGenerator: () => 'id-${nextId++}',
        clock: () => DateTime.utc(2026, 3, 1, 0, clockTick++),
      );

      final first = await repository.importSchedule(importData(name: '第一门课'));
      final second = await repository.importSchedule(importData(name: '第二门课'));
      expect(await repository.getSelectedScheduleId(), second.id);

      await repository.deleteSchedule(second.id);
      expect(await repository.getSelectedScheduleId(), first.id);
      expect(await repository.getCourses(second.id), isEmpty);

      await repository.deleteSchedule(first.id);
      expect(await repository.getSelectedScheduleId(), isNull);
    },
  );

  test(
    'rejects a missing selection and shrinking below a course week',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      nextId = 0;
      final repository = SqliteScheduleRepository(
        database,
        idGenerator: () => 'id-${nextId++}',
      );

      await expectLater(
        repository.selectSchedule('missing'),
        throwsA(isA<ValidationException>()),
      );
      final schedule = await repository.importSchedule(
        importData(weeks: const [1, 12]),
      );
      await expectLater(
        repository.updateSchedule(schedule.copyWith(totalWeeks: 10)),
        throwsA(isA<ValidationException>()),
      );
      expect((await repository.getSchedule(schedule.id))!.totalWeeks, 20);
    },
  );

  test('updates course values and normalized relations atomically', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    nextId = 0;
    final repository = SqliteScheduleRepository(
      database,
      idGenerator: () => 'id-${nextId++}',
    );
    final schedule = await repository.importSchedule(importData());
    final course = (await repository.getCourses(schedule.id)).single;

    await repository.updateCourse(
      course.copyWith(
        name: '线性代数',
        location: 'B202',
        weekInterval: [3, 2, 3],
        periods: [3, 4],
      ),
    );

    final updated = (await repository.getCourses(schedule.id)).single;
    expect(updated.name, '线性代数');
    expect(updated.location, 'B202');
    expect(updated.weekInterval, [2, 3]);
    expect(updated.periods, [3, 4]);
  });

  test('bulk-loads every course with its own weeks and periods', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    nextId = 0;
    final repository = SqliteScheduleRepository(
      database,
      idGenerator: () => 'id-${nextId++}',
    );
    final schedule = await repository.importSchedule(
      ScheduleImport(
        term: '2025-2026-2',
        courses: [
          CourseDraft(
            name: '单周课程',
            weekInterval: const [1, 3, 5],
            weekday: 2,
            periods: const [1, 2],
          ),
          CourseDraft(
            name: '双周课程',
            weekInterval: const [2, 4, 6],
            weekday: 2,
            periods: const [1, 2],
          ),
          CourseDraft(
            name: '晚间课程',
            weekInterval: const [1, 2, 3, 4],
            weekday: 5,
            periods: const [9, 10],
          ),
        ],
      ),
    );

    final courses = await repository.getCourses(schedule.id);

    expect(courses.map((course) => course.name), ['单周课程', '双周课程', '晚间课程']);
    expect(courses[0].weekInterval, [1, 3, 5]);
    expect(courses[1].weekInterval, [2, 4, 6]);
    expect(courses[2].periods, [9, 10]);
  });
}
