import 'package:flutter_test/flutter_test.dart';
import 'package:lighttable/domain/errors/validation_exception.dart';
import 'package:lighttable/domain/models/course.dart';
import 'package:lighttable/domain/models/period.dart';
import 'package:lighttable/domain/models/schedule.dart';
import 'package:lighttable/domain/utils/course_schedule_utils.dart';

void main() {
  final schedule = Schedule(
    id: 'schedule-1',
    name: '2025-2026-2',
    totalWeeks: 20,
    startDate: DateTime(2026, 3, 1),
    createdAt: DateTime(2026),
  );
  final periods = [
    Period(number: 1, startMinutes: 480, endMinutes: 525),
    Period(number: 2, startMinutes: 535, endMinutes: 580),
    Period(number: 3, startMinutes: 600, endMinutes: 645),
  ];

  Course course(String id, String name, List<int> occupiedPeriods) {
    return Course(
      id: id,
      scheduleId: schedule.id,
      name: name,
      location: '',
      teacher: '',
      weekInterval: [1, 2],
      weekday: 2,
      periods: occupiedPeriods,
    );
  }

  test('normalizes weeks and rejects non-contiguous periods', () {
    final normalized = Course(
      id: 'course',
      scheduleId: schedule.id,
      name: ' 高等数学 ',
      location: ' A101 ',
      teacher: ' 王老师 ',
      weekInterval: [3, 1, 3, 2],
      weekday: 2,
      periods: [2, 1, 2],
    );
    expect(normalized.name, '高等数学');
    expect(normalized.weekInterval, [1, 2, 3]);
    expect(normalized.periods, [1, 2]);

    expect(
      () => course('invalid', '无效课程', [1, 3]),
      throwsA(isA<ValidationException>()),
    );
  });

  test('filters and sorts courses for a week day', () {
    final result = CourseScheduleUtils.coursesFor(
      courses: [
        course('late', '后课', [3]),
        course('early', '先课', [1]),
      ],
      weekday: 2,
      week: 1,
    );
    expect(result.map((item) => item.id), ['early', 'late']);
  });

  test('returns an ongoing course before the next course', () {
    final result = CourseScheduleUtils.currentAndUpcomingCourses(
      schedule: schedule,
      courses: [
        course('current', '当前课程', [1, 2]),
        course('next', '下一课程', [3]),
      ],
      periods: periods,
      now: DateTime(2026, 3, 2, 8, 30),
    );
    expect(result.map((item) => item.id), ['current', 'next']);
  });

  test(
    'returns no upcoming course outside the term or after the last class',
    () {
      final classes = [
        course('only', '课程', [1]),
      ];
      expect(
        CourseScheduleUtils.currentAndUpcomingCourses(
          schedule: schedule,
          courses: classes,
          periods: periods,
          now: DateTime(2026, 2, 23, 8),
        ),
        isEmpty,
      );
      expect(
        CourseScheduleUtils.currentAndUpcomingCourses(
          schedule: schedule,
          courses: classes,
          periods: periods,
          now: DateTime(2026, 3, 2, 9),
        ),
        isEmpty,
      );
    },
  );
}
