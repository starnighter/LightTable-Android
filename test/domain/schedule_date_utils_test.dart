import 'package:flutter_test/flutter_test.dart';
import 'package:lighttable/domain/errors/validation_exception.dart';
import 'package:lighttable/domain/models/schedule.dart';
import 'package:lighttable/domain/utils/schedule_date_utils.dart';

void main() {
  final schedule = Schedule(
    id: 'schedule-1',
    name: '2025-2026-2',
    totalWeeks: 2,
    startDate: DateTime(2026, 3, 2),
    createdAt: DateTime(2026),
  );

  test('uses the Sunday-containing start-date week as week one', () {
    expect(
      ScheduleDateUtils.startOfWeek(schedule.startDate),
      DateTime(2026, 3, 1),
    );
    expect(
      ScheduleDateUtils.dateFor(schedule: schedule, week: 1, weekday: 1),
      DateTime(2026, 3, 1),
    );
    expect(
      ScheduleDateUtils.dateFor(schedule: schedule, week: 1, weekday: 7),
      DateTime(2026, 3, 7),
    );
  });

  test('returns null before and after the configured term', () {
    expect(
      ScheduleDateUtils.weekForDate(DateTime(2026, 2, 28), schedule),
      isNull,
    );
    expect(ScheduleDateUtils.weekForDate(DateTime(2026, 3, 1), schedule), 1);
    expect(ScheduleDateUtils.weekForDate(DateTime(2026, 3, 14), schedule), 2);
    expect(
      ScheduleDateUtils.weekForDate(DateTime(2026, 3, 15), schedule),
      isNull,
    );
  });

  test('maps Dart weekdays to the source iOS convention', () {
    expect(ScheduleDateUtils.iosWeekday(DateTime(2026, 3, 1)), 1);
    expect(ScheduleDateUtils.iosWeekday(DateTime(2026, 3, 2)), 2);
    expect(ScheduleDateUtils.iosWeekday(DateTime(2026, 3, 7)), 7);
  });

  test('rejects dates outside the schedule grid', () {
    expect(
      () => ScheduleDateUtils.dateFor(schedule: schedule, week: 0, weekday: 1),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => ScheduleDateUtils.dateFor(schedule: schedule, week: 1, weekday: 8),
      throwsA(isA<ValidationException>()),
    );
  });
}
