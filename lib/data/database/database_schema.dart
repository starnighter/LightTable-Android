import 'package:sqflite/sqflite.dart';

abstract final class DatabaseSchema {
  static const version = 1;

  static const defaultPeriods = <(int, int, int)>[
    (1, 8 * 60, 8 * 60 + 45),
    (2, 8 * 60 + 55, 9 * 60 + 40),
    (3, 10 * 60, 10 * 60 + 45),
    (4, 10 * 60 + 55, 11 * 60 + 40),
    (5, 14 * 60, 14 * 60 + 45),
    (6, 14 * 60 + 55, 15 * 60 + 40),
    (7, 16 * 60, 16 * 60 + 45),
    (8, 16 * 60 + 55, 17 * 60 + 40),
    (9, 19 * 60, 19 * 60 + 45),
    (10, 19 * 60 + 55, 20 * 60 + 40),
  ];

  static Future<void> create(Database db) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE schedules (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL CHECK (length(trim(name)) > 0),
        total_weeks INTEGER NOT NULL CHECK (total_weeks BETWEEN 1 AND 52),
        start_date TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        schedule_id TEXT NOT NULL,
        name TEXT NOT NULL CHECK (length(trim(name)) > 0),
        location TEXT NOT NULL DEFAULT '',
        teacher TEXT NOT NULL DEFAULT '',
        weekday INTEGER NOT NULL CHECK (weekday BETWEEN 1 AND 7),
        FOREIGN KEY (schedule_id) REFERENCES schedules(id) ON DELETE CASCADE
      )
    ''');
    batch.execute('''
      CREATE TABLE periods (
        period_number INTEGER PRIMARY KEY CHECK (period_number > 0),
        start_minutes INTEGER NOT NULL CHECK (start_minutes BETWEEN 0 AND 1439),
        end_minutes INTEGER NOT NULL CHECK (end_minutes BETWEEN 1 AND 1440),
        CHECK (start_minutes < end_minutes)
      )
    ''');
    batch.execute('''
      CREATE TABLE course_weeks (
        course_id TEXT NOT NULL,
        week_number INTEGER NOT NULL CHECK (week_number BETWEEN 1 AND 52),
        PRIMARY KEY (course_id, week_number),
        FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');
    batch.execute('''
      CREATE TABLE course_periods (
        course_id TEXT NOT NULL,
        period_number INTEGER NOT NULL,
        PRIMARY KEY (course_id, period_number),
        FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
        FOREIGN KEY (period_number) REFERENCES periods(period_number) ON DELETE RESTRICT
      )
    ''');
    batch.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    batch.execute('CREATE INDEX idx_courses_schedule ON courses(schedule_id)');
    batch.execute(
      'CREATE INDEX idx_courses_schedule_weekday '
      'ON courses(schedule_id, weekday)',
    );
    batch.execute(
      'CREATE INDEX idx_course_weeks_week ON course_weeks(week_number)',
    );

    for (final (number, startMinutes, endMinutes) in defaultPeriods) {
      batch.insert('periods', {
        'period_number': number,
        'start_minutes': startMinutes,
        'end_minutes': endMinutes,
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion == newVersion) {
      return;
    }
    throw UnsupportedError('缺少数据库迁移：$oldVersion -> $newVersion');
  }
}
