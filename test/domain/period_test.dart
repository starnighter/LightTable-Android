import 'package:flutter_test/flutter_test.dart';
import 'package:lighttable/domain/errors/validation_exception.dart';
import 'package:lighttable/domain/models/period.dart';

void main() {
  test('formats minute values as 24-hour times', () {
    final period = Period(
      number: 1,
      startMinutes: 8 * 60,
      endMinutes: 8 * 60 + 45,
    );

    expect(period.startTime, '08:00');
    expect(period.endTime, '08:45');
  });

  test('validates a continuous non-overlapping period sequence', () {
    final valid = [
      Period(number: 1, startMinutes: 480, endMinutes: 525),
      Period(number: 2, startMinutes: 535, endMinutes: 580),
    ];
    expect(() => Period.validateSequence(valid), returnsNormally);

    final overlap = [
      valid.first,
      Period(number: 2, startMinutes: 520, endMinutes: 560),
    ];
    expect(
      () => Period.validateSequence(overlap),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects invalid individual periods and numbering gaps', () {
    expect(
      () => Period(number: 1, startMinutes: 500, endMinutes: 500),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => Period.validateSequence([
        Period(number: 2, startMinutes: 500, endMinutes: 545),
      ]),
      throwsA(isA<ValidationException>()),
    );
  });
}
