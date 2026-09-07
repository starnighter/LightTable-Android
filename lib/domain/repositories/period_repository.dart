import '../models/period.dart';

abstract interface class PeriodRepository {
  Future<List<Period>> getPeriods();

  Future<Period> addPeriod();

  Future<void> updatePeriod(Period period);

  Future<void> deleteLastPeriod();
}
