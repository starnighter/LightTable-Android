import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lighttable/domain/errors/validation_exception.dart';
import 'package:lighttable/domain/services/schedule_import_parser.dart';

void main() {
  const allowedPeriods = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

  Map<String, Object?> validData() => {
    'term': '2025-2026-2',
    'courses': [
      {
        'name': '高等数学',
        'location': 'A101',
        'teacher': '王老师',
        'weekInterval': [1, 3, 5, 7],
        'weekday': 2,
        'period': [1, 2],
        'table': '2025-2026-2',
      },
      {
        'name': '大学英语',
        'location': '',
        'teacher': '',
        'weekInterval': [2, 4, 6, 8],
        'weekday': 4,
        'period': [5, 6],
      },
    ],
  };

  test('parses a fully validated timetable and a quoted WebView result', () {
    final encoded = jsonEncode(validData());
    final imported = ScheduleImportParser.parse(
      encoded,
      allowedPeriodNumbers: allowedPeriods,
    );
    final quoted = ScheduleImportParser.parse(
      jsonEncode(encoded),
      allowedPeriodNumbers: allowedPeriods,
    );

    expect(imported.term.toString(), '2025-2026-2');
    expect(imported.courses, hasLength(2));
    expect(imported.courses.first.weekInterval, [1, 3, 5, 7]);
    expect(imported.courses.first.periods, [1, 2]);
    expect(quoted.courses.last.weekInterval, [2, 4, 6, 8]);
  });

  test('rejects malformed JSON, error pages, and empty course data', () {
    final invalidValues = <String>[
      '{not-json',
      jsonEncode({'error': '未找到课表表格'}),
      jsonEncode({'term': '2025-2026-2', 'courses': []}),
      jsonEncode(['not', 'an', 'object']),
    ];

    for (final value in invalidValues) {
      expect(
        () => ScheduleImportParser.parse(
          value,
          allowedPeriodNumbers: allowedPeriods,
        ),
        throwsA(isA<ValidationException>()),
      );
    }
  });

  test('rejects missing fields and wrong primitive types', () {
    final missingName = validData();
    (missingName['courses']! as List).first.remove('name');
    final nonIntegerWeekday = validData();
    (nonIntegerWeekday['courses']! as List).first['weekday'] = 2.0;
    final missingLocation = validData();
    (missingLocation['courses']! as List).first.remove('location');

    for (final value in [missingName, nonIntegerWeekday, missingLocation]) {
      expect(
        () => ScheduleImportParser.parse(
          jsonEncode(value),
          allowedPeriodNumbers: allowedPeriods,
        ),
        throwsA(isA<ValidationException>()),
      );
    }
  });

  test('rejects invalid term, weekday, weeks, and periods', () {
    final malformedTerm = validData()..['term'] = '2025-2';
    final weekday = validData();
    (weekday['courses']! as List).first['weekday'] = 8;
    final weeks = validData();
    (weeks['courses']! as List).first['weekInterval'] = [0, 1];
    final unsortedWeeks = validData();
    (unsortedWeeks['courses']! as List).first['weekInterval'] = [2, 1];
    final periods = validData();
    (periods['courses']! as List).first['period'] = [1, 3];
    final missingPeriod = validData();
    (missingPeriod['courses']! as List).first['period'] = [10, 11];
    final mismatchedTerm = validData();
    (mismatchedTerm['courses']! as List).first['table'] = '2025-2026-1';

    for (final value in [
      malformedTerm,
      weekday,
      weeks,
      unsortedWeeks,
      periods,
      missingPeriod,
      mismatchedTerm,
    ]) {
      expect(
        () => ScheduleImportParser.parse(
          jsonEncode(value),
          allowedPeriodNumbers: allowedPeriods,
        ),
        throwsA(isA<ValidationException>()),
      );
    }
  });
}
