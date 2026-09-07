import '../errors/validation_exception.dart';
import 'academic_term.dart';
import 'course.dart';

final class ScheduleImport {
  ScheduleImport({required String term, required List<CourseDraft> courses})
    : term = AcademicTerm.parse(term),
      courses = List<CourseDraft>.unmodifiable(courses) {
    if (courses.isEmpty) {
      throw const ValidationException('导入的课表不能没有课程');
    }
  }

  final AcademicTerm term;
  final List<CourseDraft> courses;
}
