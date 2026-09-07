import '../errors/validation_exception.dart';

final class Schedule {
  Schedule({
    required this.id,
    required String name,
    required this.totalWeeks,
    required DateTime startDate,
    required this.createdAt,
  }) : name = name.trim(),
       startDate = DateTime(startDate.year, startDate.month, startDate.day) {
    if (id.trim().isEmpty) {
      throw const ValidationException('课表 ID 不能为空');
    }
    if (this.name.isEmpty) {
      throw const ValidationException('课表名称不能为空');
    }
    if (totalWeeks < 1 || totalWeeks > 52) {
      throw const ValidationException('学期周数必须在 1 到 52 之间');
    }
  }

  final String id;
  final String name;
  final int totalWeeks;
  final DateTime startDate;
  final DateTime createdAt;

  Schedule copyWith({String? name, int? totalWeeks, DateTime? startDate}) {
    return Schedule(
      id: id,
      name: name ?? this.name,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt,
    );
  }
}
