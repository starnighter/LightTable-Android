import 'dart:collection';

import '../errors/validation_exception.dart';

final class Course {
  Course({
    required this.id,
    required this.scheduleId,
    required String name,
    required String location,
    required String teacher,
    required List<int> weekInterval,
    required this.weekday,
    required List<int> periods,
  }) : name = name.trim(),
       location = location.trim(),
       teacher = teacher.trim(),
       weekInterval = _normalizeWeeks(weekInterval),
       periods = _normalizePeriods(periods) {
    if (id.trim().isEmpty || scheduleId.trim().isEmpty) {
      throw const ValidationException('课程及所属课表 ID 不能为空');
    }
    _validateShared(this.name, this.weekInterval, weekday, this.periods);
  }

  final String id;
  final String scheduleId;
  final String name;
  final String location;
  final String teacher;
  final List<int> weekInterval;
  final int weekday;
  final List<int> periods;

  int get firstPeriod => periods.first;
  int get lastPeriod => periods.last;

  Course copyWith({
    String? name,
    String? location,
    String? teacher,
    List<int>? weekInterval,
    int? weekday,
    List<int>? periods,
  }) {
    return Course(
      id: id,
      scheduleId: scheduleId,
      name: name ?? this.name,
      location: location ?? this.location,
      teacher: teacher ?? this.teacher,
      weekInterval: weekInterval ?? this.weekInterval,
      weekday: weekday ?? this.weekday,
      periods: periods ?? this.periods,
    );
  }
}

final class CourseDraft {
  CourseDraft({
    required String name,
    String location = '',
    String teacher = '',
    required List<int> weekInterval,
    required this.weekday,
    required List<int> periods,
  }) : name = name.trim(),
       location = location.trim(),
       teacher = teacher.trim(),
       weekInterval = _normalizeWeeks(weekInterval),
       periods = _normalizePeriods(periods) {
    _validateShared(this.name, this.weekInterval, weekday, this.periods);
  }

  final String name;
  final String location;
  final String teacher;
  final List<int> weekInterval;
  final int weekday;
  final List<int> periods;

  Course toCourse({required String id, required String scheduleId}) {
    return Course(
      id: id,
      scheduleId: scheduleId,
      name: name,
      location: location,
      teacher: teacher,
      weekInterval: weekInterval,
      weekday: weekday,
      periods: periods,
    );
  }
}

List<int> _normalizeWeeks(List<int> values) {
  final sorted = SplayTreeSet<int>.from(values).toList(growable: false);
  return List<int>.unmodifiable(sorted);
}

List<int> _normalizePeriods(List<int> values) {
  final sorted = SplayTreeSet<int>.from(values).toList(growable: false);
  return List<int>.unmodifiable(sorted);
}

void _validateShared(
  String name,
  List<int> weeks,
  int weekday,
  List<int> periods,
) {
  if (name.isEmpty) {
    throw const ValidationException('课程名称不能为空');
  }
  if (weekday < 1 || weekday > 7) {
    throw const ValidationException('星期必须在 1 到 7 之间');
  }
  if (weeks.isEmpty || weeks.any((week) => week < 1 || week > 52)) {
    throw const ValidationException('课程周次必须在 1 到 52 之间且不能为空');
  }
  if (periods.isEmpty || periods.any((period) => period < 1)) {
    throw const ValidationException('课程节次必须为正整数且不能为空');
  }
  for (var index = 1; index < periods.length; index++) {
    if (periods[index] != periods[index - 1] + 1) {
      throw const ValidationException('课程节次必须连续');
    }
  }
}
