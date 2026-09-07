import 'package:flutter_test/flutter_test.dart';
import 'package:lighttable/data/database/database_schema.dart';

import '../support/test_database.dart';

void main() {
  test(
    'creates the full schema and ten default periods exactly once',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);

      final firstOpen = database.database;
      final secondOpen = database.database;
      final db = await firstOpen;
      expect(await secondOpen, same(db));
      final tableRows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
      );
      final tableNames = tableRows.map((row) => row['name']);
      expect(
        tableNames,
        containsAll([
          'app_settings',
          'course_periods',
          'course_weeks',
          'courses',
          'periods',
          'schedules',
        ]),
      );
      expect(await db.query('periods'), hasLength(10));
      expect(
        (await db.rawQuery('PRAGMA user_version')).single['user_version'],
        DatabaseSchema.version,
      );
      expect(
        (await db.rawQuery('PRAGMA foreign_keys')).single['foreign_keys'],
        1,
      );

      final sameDb = await database.database;
      expect(sameDb, same(db));
      expect(await sameDb.query('periods'), hasLength(10));
    },
  );

  test('enforces foreign keys and cascades schedule deletion', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final db = await database.database;

    await db.insert('schedules', {
      'id': 'schedule',
      'name': '课表',
      'total_weeks': 20,
      'start_date': '2026-03-01',
      'created_at': 0,
    });
    await db.insert('courses', {
      'id': 'course',
      'schedule_id': 'schedule',
      'name': '课程',
      'location': '',
      'teacher': '',
      'weekday': 2,
    });
    await db.insert('course_weeks', {'course_id': 'course', 'week_number': 1});
    await db.insert('course_periods', {
      'course_id': 'course',
      'period_number': 1,
    });

    await db.delete('schedules', where: 'id = ?', whereArgs: ['schedule']);
    expect(await db.query('courses'), isEmpty);
    expect(await db.query('course_weeks'), isEmpty);
    expect(await db.query('course_periods'), isEmpty);
  });
}
