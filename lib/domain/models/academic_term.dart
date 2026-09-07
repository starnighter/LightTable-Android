import '../errors/validation_exception.dart';

final class AcademicTerm {
  const AcademicTerm._({
    required this.firstYear,
    required this.secondYear,
    required this.semester,
  });

  factory AcademicTerm.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{4})-([12])$').firstMatch(value.trim());
    if (match == null) {
      throw const ValidationException('学期格式必须为 YYYY-YYYY-1 或 YYYY-YYYY-2');
    }

    final firstYear = int.parse(match.group(1)!);
    final secondYear = int.parse(match.group(2)!);
    final semester = int.parse(match.group(3)!);
    if (secondYear != firstYear + 1) {
      throw const ValidationException('学期的两个年份必须连续');
    }

    return AcademicTerm._(
      firstYear: firstYear,
      secondYear: secondYear,
      semester: semester,
    );
  }

  final int firstYear;
  final int secondYear;
  final int semester;

  DateTime get defaultStartDate => semester == 1
      ? DateTime(firstYear, DateTime.september)
      : DateTime(secondYear, DateTime.march);

  @override
  String toString() => '$firstYear-$secondYear-$semester';
}
