import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/errors/validation_exception.dart';
import '../../domain/models/course.dart';
import '../../domain/models/schedule.dart';
import '../../domain/models/schedule_import.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../database/database_value_codec.dart';
import '../database/light_table_database.dart';

typedef IdGenerator = String Function();
typedef Clock = DateTime Function();

final class SqliteScheduleRepository implements ScheduleRepository {
  SqliteScheduleRepository(
    this._database, {
    IdGenerator? idGenerator,
    Clock? clock,
  }) : _idGenerator = idGenerator ?? (() => const Uuid().v4()),
       _clock = clock ?? DateTime.now;

  static const _selectedScheduleKey = 'selected_schedule_id';

  final LightTableDatabase _database;
  final IdGenerator _idGenerator;
  final Clock _clock;

  @override
  Future<List<Schedule>> getSchedules() async {
    final db = await _database.database;
    final rows = await db.query('schedules', orderBy: 'created_at ASC, id ASC');
    return rows.map(_scheduleFromRow).toList(growable: false);
  }

  @override
  Future<Schedule?> getSchedule(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _scheduleFromRow(rows.single);
  }

  @override
  Future<List<Course>> getCourses(String scheduleId) async {
    final db = await _database.database;
    return _readCourses(db, scheduleId);
  }

  @override
  Future<String?> getSelectedScheduleId() async {
    final db = await _database.database;
    return _readSelectedScheduleId(db);
  }

  @override
  Future<Schedule?> getSelectedSchedule() async {
    final id = await getSelectedScheduleId();
    return id == null ? null : getSchedule(id);
  }

  @override
  Future<void> selectSchedule(String? scheduleId) async {
    final db = await _database.database;
    await db.transaction((transaction) async {
      if (scheduleId == null) {
        await transaction.delete(
          'app_settings',
          where: 'key = ?',
          whereArgs: [_selectedScheduleKey],
        );
        return;
      }
      await _requireSchedule(transaction, scheduleId);
      await _writeSelectedScheduleId(transaction, scheduleId);
    });
  }

  @override
  Future<Schedule> importSchedule(ScheduleImport data) async {
    const defaultTotalWeeks = 20;
    for (final course in data.courses) {
      if (course.weekInterval.any((week) => week > defaultTotalWeeks)) {
        throw const ValidationException('课程周次超出默认的 20 周学期范围');
      }
    }

    final schedule = Schedule(
      id: _idGenerator(),
      name: data.term.toString(),
      totalWeeks: defaultTotalWeeks,
      startDate: data.term.defaultStartDate,
      createdAt: _clock(),
    );
    final courses = data.courses
        .map(
          (draft) =>
              draft.toCourse(id: _idGenerator(), scheduleId: schedule.id),
        )
        .toList(growable: false);

    final db = await _database.database;
    await db.transaction((transaction) async {
      await transaction.insert('schedules', _scheduleToRow(schedule));
      for (final course in courses) {
        await _insertCourse(transaction, course, schedule.totalWeeks);
      }
      await _writeSelectedScheduleId(transaction, schedule.id);
    });
    return schedule;
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    final db = await _database.database;
    await db.transaction((transaction) async {
      await _requireSchedule(transaction, schedule.id);
      final rows = await transaction.rawQuery(
        '''
        SELECT MAX(cw.week_number) AS max_week
        FROM course_weeks cw
        JOIN courses c ON c.id = cw.course_id
        WHERE c.schedule_id = ?
        ''',
        [schedule.id],
      );
      final maxWeek = rows.single['max_week'] as int?;
      if (maxWeek != null && maxWeek > schedule.totalWeeks) {
        throw ValidationException(
          '课程包含第 $maxWeek 周，不能把学期缩短为 ${schedule.totalWeeks} 周',
        );
      }
      await transaction.update(
        'schedules',
        {
          'name': schedule.name,
          'total_weeks': schedule.totalWeeks,
          'start_date': DatabaseValueCodec.encodeDate(schedule.startDate),
        },
        where: 'id = ?',
        whereArgs: [schedule.id],
      );
    });
  }

  @override
  Future<void> updateCourse(Course course) async {
    final db = await _database.database;
    await db.transaction((transaction) async {
      final schedule = await _requireSchedule(transaction, course.scheduleId);
      await _replaceCourse(transaction, course, schedule.totalWeeks);
    });
  }

  @override
  Future<Course> addCourse(String scheduleId, CourseDraft draft) async {
    final db = await _database.database;
    final course = draft.toCourse(id: _idGenerator(), scheduleId: scheduleId);
    await db.transaction((transaction) async {
      final schedule = await _requireSchedule(transaction, scheduleId);
      await _insertCourse(transaction, course, schedule.totalWeeks);
    });
    return course;
  }

  @override
  Future<void> updateCourseOccurrence({
    required Course course,
    required int sourceWeek,
    required int targetWeek,
    required int targetWeekday,
  }) async {
    final db = await _database.database;
    await db.transaction((transaction) async {
      final schedule = await _requireSchedule(transaction, course.scheduleId);
      if (sourceWeek < 1 || sourceWeek > schedule.totalWeeks) {
        throw const ValidationException('原课程日期超出学期范围');
      }
      if (targetWeek < 1 || targetWeek > schedule.totalWeeks) {
        throw const ValidationException('调整后的课程日期超出学期范围');
      }
      if (targetWeekday < 1 || targetWeekday > 7) {
        throw const ValidationException('星期必须在 1 到 7 之间');
      }

      final storedRows = await transaction.query(
        'courses',
        columns: ['weekday'],
        where: 'id = ? AND schedule_id = ?',
        whereArgs: [course.id, course.scheduleId],
        limit: 1,
      );
      if (storedRows.isEmpty) {
        throw const ValidationException('要更新的课程不存在');
      }
      final weekRows = await transaction.query(
        'course_weeks',
        columns: ['week_number'],
        where: 'course_id = ?',
        whereArgs: [course.id],
        orderBy: 'week_number ASC',
      );
      final storedWeeks = weekRows
          .map((row) => row['week_number']! as int)
          .toList(growable: false);
      if (!storedWeeks.contains(sourceWeek)) {
        throw const ValidationException('当前周没有这节课程');
      }

      final storedWeekday = storedRows.single['weekday']! as int;
      if (sourceWeek == targetWeek && storedWeekday == targetWeekday) {
        await _replaceCourse(
          transaction,
          course.copyWith(weekInterval: storedWeeks),
          schedule.totalWeeks,
        );
        return;
      }

      await _requirePeriods(transaction, course.periods);
      if (storedWeeks.length == 1) {
        await _replaceCourse(
          transaction,
          course.copyWith(weekInterval: [targetWeek], weekday: targetWeekday),
          schedule.totalWeeks,
        );
        return;
      }

      final remainingCourse = course.copyWith(
        weekInterval: storedWeeks.where((week) => week != sourceWeek).toList(),
        weekday: storedWeekday,
      );
      await _replaceCourse(transaction, remainingCourse, schedule.totalWeeks);
      final movedCourse = Course(
        id: _idGenerator(),
        scheduleId: course.scheduleId,
        name: course.name,
        location: course.location,
        teacher: course.teacher,
        weekInterval: [targetWeek],
        weekday: targetWeekday,
        periods: course.periods,
      );
      await _insertCourse(transaction, movedCourse, schedule.totalWeeks);
    });
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    final db = await _database.database;
    await db.transaction((transaction) async {
      final selectedId = await _readSelectedScheduleId(transaction);
      final deleted = await transaction.delete(
        'schedules',
        where: 'id = ?',
        whereArgs: [scheduleId],
      );
      if (deleted == 0 || selectedId != scheduleId) {
        return;
      }

      final remaining = await transaction.query(
        'schedules',
        columns: ['id'],
        orderBy: 'created_at ASC, id ASC',
        limit: 1,
      );
      if (remaining.isEmpty) {
        await transaction.delete(
          'app_settings',
          where: 'key = ?',
          whereArgs: [_selectedScheduleKey],
        );
      } else {
        await _writeSelectedScheduleId(
          transaction,
          remaining.single['id']! as String,
        );
      }
    });
  }

  static Schedule _scheduleFromRow(Map<String, Object?> row) {
    return Schedule(
      id: row['id']! as String,
      name: row['name']! as String,
      totalWeeks: row['total_weeks']! as int,
      startDate: DatabaseValueCodec.decodeDate(row['start_date']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
        isUtc: true,
      ).toLocal(),
    );
  }

  static Map<String, Object?> _scheduleToRow(Schedule schedule) {
    return {
      'id': schedule.id,
      'name': schedule.name,
      'total_weeks': schedule.totalWeeks,
      'start_date': DatabaseValueCodec.encodeDate(schedule.startDate),
      'created_at': schedule.createdAt.toUtc().millisecondsSinceEpoch,
    };
  }

  static Map<String, Object?> _courseToRow(Course course) {
    return {
      'id': course.id,
      'schedule_id': course.scheduleId,
      'name': course.name,
      'location': course.location,
      'teacher': course.teacher,
      'weekday': course.weekday,
    };
  }

  static Future<List<Course>> _readCourses(
    DatabaseExecutor executor,
    String scheduleId,
  ) async {
    final courseRows = await executor.query(
      'courses',
      where: 'schedule_id = ?',
      whereArgs: [scheduleId],
      orderBy: 'weekday ASC, name ASC',
    );
    if (courseRows.isEmpty) return const [];

    final weekRows = await executor.rawQuery(
      '''
      SELECT cw.course_id, cw.week_number
      FROM course_weeks cw
      INNER JOIN courses c ON c.id = cw.course_id
      WHERE c.schedule_id = ?
      ORDER BY cw.course_id ASC, cw.week_number ASC
      ''',
      [scheduleId],
    );
    final periodRows = await executor.rawQuery(
      '''
      SELECT cp.course_id, cp.period_number
      FROM course_periods cp
      INNER JOIN courses c ON c.id = cp.course_id
      WHERE c.schedule_id = ?
      ORDER BY cp.course_id ASC, cp.period_number ASC
      ''',
      [scheduleId],
    );
    final weeksByCourse = <String, List<int>>{};
    for (final row in weekRows) {
      (weeksByCourse[row['course_id']! as String] ??= []).add(
        row['week_number']! as int,
      );
    }
    final periodsByCourse = <String, List<int>>{};
    for (final row in periodRows) {
      (periodsByCourse[row['course_id']! as String] ??= []).add(
        row['period_number']! as int,
      );
    }

    final result = <Course>[];
    for (final row in courseRows) {
      final courseId = row['id']! as String;
      result.add(
        Course(
          id: courseId,
          scheduleId: row['schedule_id']! as String,
          name: row['name']! as String,
          location: row['location']! as String,
          teacher: row['teacher']! as String,
          weekInterval: weeksByCourse[courseId] ?? const [],
          weekday: row['weekday']! as int,
          periods: periodsByCourse[courseId] ?? const [],
        ),
      );
    }
    result.sort((a, b) {
      final byWeekday = a.weekday.compareTo(b.weekday);
      if (byWeekday != 0) {
        return byWeekday;
      }
      final byPeriod = a.firstPeriod.compareTo(b.firstPeriod);
      return byPeriod != 0 ? byPeriod : a.name.compareTo(b.name);
    });
    return result;
  }

  static Future<void> _insertCourse(
    DatabaseExecutor executor,
    Course course,
    int totalWeeks,
  ) async {
    if (course.weekInterval.any((week) => week > totalWeeks)) {
      throw const ValidationException('课程周次超出所属课表的学期范围');
    }
    await _requirePeriods(executor, course.periods);
    await executor.insert('courses', _courseToRow(course));
    await _insertCourseRelations(executor, course);
  }

  static Future<void> _insertCourseRelations(
    DatabaseExecutor executor,
    Course course,
  ) async {
    for (final week in course.weekInterval) {
      await executor.insert('course_weeks', {
        'course_id': course.id,
        'week_number': week,
      });
    }
    for (final period in course.periods) {
      await executor.insert('course_periods', {
        'course_id': course.id,
        'period_number': period,
      });
    }
  }

  static Future<void> _replaceCourse(
    DatabaseExecutor executor,
    Course course,
    int totalWeeks,
  ) async {
    if (course.weekInterval.any((week) => week > totalWeeks)) {
      throw const ValidationException('课程周次超出所属课表的学期范围');
    }
    await _requirePeriods(executor, course.periods);
    final changed = await executor.update(
      'courses',
      _courseToRow(course),
      where: 'id = ? AND schedule_id = ?',
      whereArgs: [course.id, course.scheduleId],
    );
    if (changed != 1) {
      throw const ValidationException('要更新的课程不存在');
    }
    await executor.delete(
      'course_weeks',
      where: 'course_id = ?',
      whereArgs: [course.id],
    );
    await executor.delete(
      'course_periods',
      where: 'course_id = ?',
      whereArgs: [course.id],
    );
    await _insertCourseRelations(executor, course);
  }

  static Future<void> _requirePeriods(
    DatabaseExecutor executor,
    List<int> periodNumbers,
  ) async {
    final placeholders = List.filled(periodNumbers.length, '?').join(',');
    final rows = await executor.rawQuery(
      'SELECT period_number FROM periods '
      'WHERE period_number IN ($placeholders)',
      periodNumbers,
    );
    if (rows.length != periodNumbers.length) {
      throw const ValidationException('课程引用了尚未配置的节次');
    }
  }

  static Future<Schedule> _requireSchedule(
    DatabaseExecutor executor,
    String scheduleId,
  ) async {
    final rows = await executor.query(
      'schedules',
      where: 'id = ?',
      whereArgs: [scheduleId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const ValidationException('指定的课表不存在');
    }
    return _scheduleFromRow(rows.single);
  }

  static Future<String?> _readSelectedScheduleId(
    DatabaseExecutor executor,
  ) async {
    final rows = await executor.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_selectedScheduleKey],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['value']! as String;
  }

  static Future<void> _writeSelectedScheduleId(
    DatabaseExecutor executor,
    String scheduleId,
  ) async {
    await executor.insert('app_settings', {
      'key': _selectedScheduleKey,
      'value': scheduleId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
