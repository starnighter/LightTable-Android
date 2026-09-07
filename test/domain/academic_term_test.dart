import 'package:flutter_test/flutter_test.dart';
import 'package:lighttable/domain/errors/validation_exception.dart';
import 'package:lighttable/domain/models/academic_term.dart';

void main() {
  test('parses both semesters and derives their default start dates', () {
    final autumn = AcademicTerm.parse('2025-2026-1');
    final spring = AcademicTerm.parse('2025-2026-2');

    expect(autumn.defaultStartDate, DateTime(2025, 9));
    expect(spring.defaultStartDate, DateTime(2026, 3));
    expect(spring.toString(), '2025-2026-2');
  });

  test('rejects malformed and non-consecutive terms', () {
    for (final value in ['2025-2', '2025-2027-1', '2025-2026-3']) {
      expect(
        () => AcademicTerm.parse(value),
        throwsA(isA<ValidationException>()),
      );
    }
  });
}
