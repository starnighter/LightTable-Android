import '../models/course.dart';
import '../models/period.dart';
import '../models/schedule.dart';
import 'schedule_date_utils.dart';

abstract final class CourseScheduleUtils {
  static List<Course> coursesFor({
    required Iterable<Course> courses,
    required int weekday,
    required int week,
  }) {
    final result = courses
        .where(
          (course) =>
              course.weekday == weekday && course.weekInterval.contains(week),
        )
        .toList(growable: false);
    result.sort(_compareCourseOrder);
    return result;
  }

  static List<Course> currentAndUpcomingCourses({
    required Schedule schedule,
    required Iterable<Course> courses,
    required Iterable<Period> periods,
    required DateTime now,
    int limit = 2,
  }) {
    if (limit < 1) {
      return const [];
    }
    final week = ScheduleDateUtils.weekForDate(now, schedule);
    if (week == null) {
      return const [];
    }

    final periodByNumber = <int, Period>{
      for (final period in periods) period.number: period,
    };
    final minuteOfDay = now.hour * 60 + now.minute;
    final todayCourses = coursesFor(
      courses: courses,
      weekday: ScheduleDateUtils.iosWeekday(now),
      week: week,
    );

    final eligible = todayCourses
        .where((course) {
          final end = periodByNumber[course.lastPeriod];
          return end != null && end.endMinutes > minuteOfDay;
        })
        .toList(growable: false);
    eligible.sort((a, b) {
      final aStart = periodByNumber[a.firstPeriod]?.startMinutes ?? 1440;
      final bStart = periodByNumber[b.firstPeriod]?.startMinutes ?? 1440;
      final byStart = aStart.compareTo(bStart);
      return byStart != 0 ? byStart : _compareCourseOrder(a, b);
    });
    return eligible.take(limit).toList(growable: false);
  }

  static int _compareCourseOrder(Course a, Course b) {
    final byPeriod = a.firstPeriod.compareTo(b.firstPeriod);
    if (byPeriod != 0) {
      return byPeriod;
    }
    return a.name.compareTo(b.name);
  }
}
