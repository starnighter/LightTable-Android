import 'package:sqflite/sqflite.dart';

import '../../domain/errors/validation_exception.dart';
import '../../domain/models/period.dart';
import '../../domain/repositories/period_repository.dart';
import '../database/light_table_database.dart';

final class SqlitePeriodRepository implements PeriodRepository {
  SqlitePeriodRepository(this._database);

  final LightTableDatabase _database;

  @override
  Future<List<Period>> getPeriods() async {
    final db = await _database.database;
    return _readPeriods(db);
  }

  @override
  Future<Period> addPeriod() async {
    final db = await _database.database;
    return db.transaction((transaction) async {
      final periods = await _readPeriods(transaction);
      final Period newPeriod;
      if (periods.isEmpty) {
        newPeriod = Period(
          number: 1,
          startMinutes: 8 * 60,
          endMinutes: 8 * 60 + 45,
        );
      } else {
        final last = periods.last;
        final start = last.endMinutes + 10;
        final end = start + 45;
        if (end > 1440) {
          throw const ValidationException('当天已没有足够时间新增节次');
        }
        newPeriod = Period(
          number: last.number + 1,
          startMinutes: start,
          endMinutes: end,
        );
      }
      await transaction.insert('periods', _periodToRow(newPeriod));
      return newPeriod;
    });
  }

  @override
  Future<void> updatePeriod(Period period) async {
    final db = await _database.database;
    await db.transaction((transaction) async {
      final periods = await _readPeriods(transaction);
      final index = periods.indexWhere((item) => item.number == period.number);
      if (index == -1) {
        throw const ValidationException('要更新的节次不存在');
      }
      periods[index] = period;
      Period.validateSequence(periods);
      await transaction.update(
        'periods',
        _periodToRow(period),
        where: 'period_number = ?',
        whereArgs: [period.number],
      );
    });
  }

  @override
  Future<void> deleteLastPeriod() async {
    final db = await _database.database;
    await db.transaction((transaction) async {
      final periods = await _readPeriods(transaction);
      if (periods.length <= 1) {
        throw const ValidationException('至少需要保留一个节次');
      }
      final last = periods.last;
      final references = await transaction.query(
        'course_periods',
        columns: ['course_id'],
        where: 'period_number = ?',
        whereArgs: [last.number],
        limit: 1,
      );
      if (references.isNotEmpty) {
        throw const ValidationException('仍有课程使用最后一个节次，无法删除');
      }
      await transaction.delete(
        'periods',
        where: 'period_number = ?',
        whereArgs: [last.number],
      );
    });
  }

  static Future<List<Period>> _readPeriods(DatabaseExecutor executor) async {
    final rows = await executor.query('periods', orderBy: 'period_number ASC');
    return rows
        .map(
          (row) => Period(
            number: row['period_number']! as int,
            startMinutes: row['start_minutes']! as int,
            endMinutes: row['end_minutes']! as int,
          ),
        )
        .toList(growable: true);
  }

  static Map<String, Object?> _periodToRow(Period period) {
    return {
      'period_number': period.number,
      'start_minutes': period.startMinutes,
      'end_minutes': period.endMinutes,
    };
  }
}
