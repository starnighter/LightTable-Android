import '../../domain/models/schedule.dart';

abstract final class UiFormatters {
  static String date(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static String error(Object error) {
    return error.toString().replaceFirst('ValidationException: ', '');
  }

  static int initialWeek(DateTime now, Schedule schedule) {
    final firstSunday = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day - schedule.startDate.weekday % 7,
    );
    final today = DateTime(now.year, now.month, now.day);
    final difference = DateTime.utc(today.year, today.month, today.day)
        .difference(
          DateTime.utc(firstSunday.year, firstSunday.month, firstSunday.day),
        )
        .inDays;
    return (difference ~/ 7 + 1).clamp(1, schedule.totalWeeks);
  }
}
