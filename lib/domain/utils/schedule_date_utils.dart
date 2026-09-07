import '../errors/validation_exception.dart';
import '../models/schedule.dart';

abstract final class ScheduleDateUtils {
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime startOfWeek(DateTime date) {
    final day = startOfDay(date);
    final daysSinceSunday = day.weekday % DateTime.daysPerWeek;
    return DateTime(day.year, day.month, day.day - daysSinceSunday);
  }

  static int? weekForDate(DateTime date, Schedule schedule) {
    final termStart = startOfWeek(schedule.startDate);
    final target = startOfWeek(date);
    final dayDifference =
        _calendarDayIndex(target) - _calendarDayIndex(termStart);
    final week = dayDifference ~/ DateTime.daysPerWeek + 1;
    return week >= 1 && week <= schedule.totalWeeks ? week : null;
  }

  static DateTime dateFor({
    required Schedule schedule,
    required int week,
    required int weekday,
  }) {
    if (week < 1 || week > schedule.totalWeeks) {
      throw const ValidationException('目标周次超出学期范围');
    }
    if (weekday < 1 || weekday > 7) {
      throw const ValidationException('星期必须在 1 到 7 之间');
    }
    final termStart = startOfWeek(schedule.startDate);
    final daysToAdd = (week - 1) * DateTime.daysPerWeek + weekday - 1;
    return DateTime(termStart.year, termStart.month, termStart.day + daysToAdd);
  }

  static int iosWeekday(DateTime date) => date.weekday % 7 + 1;

  static int _calendarDayIndex(DateTime date) {
    return DateTime.utc(
          date.year,
          date.month,
          date.day,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }
}
