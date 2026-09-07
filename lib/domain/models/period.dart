import '../errors/validation_exception.dart';

final class Period {
  const Period._({
    required this.number,
    required this.startMinutes,
    required this.endMinutes,
  });

  factory Period({
    required int number,
    required int startMinutes,
    required int endMinutes,
  }) {
    if (number < 1) {
      throw const ValidationException('节次编号必须为正整数');
    }
    if (startMinutes < 0 || startMinutes >= 1440) {
      throw const ValidationException('开始时间必须在当天范围内');
    }
    if (endMinutes < 1 || endMinutes > 1440 || startMinutes >= endMinutes) {
      throw const ValidationException('结束时间必须晚于开始时间');
    }
    return Period._(
      number: number,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    );
  }

  final int number;
  final int startMinutes;
  final int endMinutes;

  String get startTime => formatMinutes(startMinutes);
  String get endTime => formatMinutes(endMinutes);

  Period copyWith({int? startMinutes, int? endMinutes}) {
    return Period(
      number: number,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }

  static String formatMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  static void validateSequence(List<Period> periods) {
    if (periods.isEmpty) {
      throw const ValidationException('至少需要保留一个节次');
    }
    final sorted = [...periods]..sort((a, b) => a.number.compareTo(b.number));
    for (var index = 0; index < sorted.length; index++) {
      if (sorted[index].number != index + 1) {
        throw const ValidationException('节次编号必须从 1 开始连续排列');
      }
      if (index > 0 &&
          sorted[index].startMinutes < sorted[index - 1].endMinutes) {
        throw const ValidationException('相邻节次时间不能重叠');
      }
    }
  }
}
