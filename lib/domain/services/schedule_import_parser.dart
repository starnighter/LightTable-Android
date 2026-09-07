import 'dart:convert';

import '../errors/validation_exception.dart';
import '../models/course.dart';
import '../models/schedule_import.dart';

abstract final class ScheduleImportParser {
  static ScheduleImport parse(
    String rawData, {
    required Set<int> allowedPeriodNumbers,
  }) {
    if (rawData.trim().isEmpty) {
      throw const ValidationException('网页没有返回课表数据');
    }
    if (allowedPeriodNumbers.isEmpty) {
      throw const ValidationException('尚未配置可用节次');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(rawData);
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }
    } on FormatException {
      throw const ValidationException('网页返回的课表数据不是有效 JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ValidationException('网页返回的课表数据结构不正确');
    }

    final pageError = decoded['error'];
    if (pageError != null) {
      throw const ValidationException('当前页面没有可导入的课表');
    }

    final term = _requiredString(decoded, 'term', '学期');
    final rawCourses = decoded['courses'];
    if (rawCourses is! List || rawCourses.isEmpty) {
      throw const ValidationException('课表必须包含至少一门课程');
    }
    if (rawCourses.length > 500) {
      throw const ValidationException('网页返回的课程数量异常');
    }

    final courses = <CourseDraft>[];
    for (var index = 0; index < rawCourses.length; index++) {
      final rawCourse = rawCourses[index];
      if (rawCourse is! Map<String, dynamic>) {
        throw ValidationException('第 ${index + 1} 门课程的数据结构不正确');
      }
      courses.add(
        _parseCourse(
          rawCourse,
          index: index,
          term: term,
          allowedPeriodNumbers: allowedPeriodNumbers,
        ),
      );
    }

    return ScheduleImport(term: term, courses: courses);
  }

  static CourseDraft _parseCourse(
    Map<String, dynamic> rawCourse, {
    required int index,
    required String term,
    required Set<int> allowedPeriodNumbers,
  }) {
    final number = index + 1;
    final name = _requiredString(rawCourse, 'name', '第 $number 门课程名称');
    final teacher = _requiredString(
      rawCourse,
      'teacher',
      '第 $number 门课程教师',
      allowEmpty: true,
    );
    final location = _requiredString(
      rawCourse,
      'location',
      '第 $number 门课程地点',
      allowEmpty: true,
    );
    if (name.length > 200 || teacher.length > 200 || location.length > 200) {
      throw ValidationException('第 $number 门课程包含过长文本');
    }

    final weekday = rawCourse['weekday'];
    if (weekday is! int || weekday < 1 || weekday > 7) {
      throw ValidationException('第 $number 门课程星期必须为 1 到 7 的整数');
    }

    final weeks = _requiredIntegerList(
      rawCourse,
      'weekInterval',
      '第 $number 门课程周次',
    );
    if (weeks.any((week) => week < 1 || week > 20)) {
      throw ValidationException('第 $number 门课程周次必须在 1 到 20 之间');
    }

    final periods = _requiredIntegerList(
      rawCourse,
      'period',
      '第 $number 门课程节次',
    );
    if (periods.any((period) => !allowedPeriodNumbers.contains(period))) {
      throw ValidationException('第 $number 门课程引用了未配置的节次');
    }
    for (var periodIndex = 1; periodIndex < periods.length; periodIndex++) {
      if (periods[periodIndex] != periods[periodIndex - 1] + 1) {
        throw ValidationException('第 $number 门课程节次必须连续');
      }
    }

    final courseTerm = rawCourse['table'];
    if (courseTerm != null &&
        (courseTerm is! String ||
            (courseTerm.trim().isNotEmpty && courseTerm.trim() != term))) {
      throw ValidationException('第 $number 门课程所属学期不一致');
    }

    return CourseDraft(
      name: name,
      location: location,
      teacher: teacher,
      weekInterval: weeks,
      weekday: weekday,
      periods: periods,
    );
  }

  static String _requiredString(
    Map<String, dynamic> object,
    String key,
    String label, {
    bool allowEmpty = false,
  }) {
    final value = object[key];
    if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
      throw ValidationException('$label 缺失或格式不正确');
    }
    return value.trim();
  }

  static List<int> _requiredIntegerList(
    Map<String, dynamic> object,
    String key,
    String label,
  ) {
    final value = object[key];
    if (value is! List || value.isEmpty || value.any((item) => item is! int)) {
      throw ValidationException('$label 必须是非空整数数组');
    }
    final integers = value.cast<int>();
    if (integers.toSet().length != integers.length) {
      throw ValidationException('$label 不能包含重复值');
    }
    for (var index = 1; index < integers.length; index++) {
      if (integers[index] <= integers[index - 1]) {
        throw ValidationException('$label 必须按升序排列');
      }
    }
    return List.unmodifiable(integers);
  }
}
