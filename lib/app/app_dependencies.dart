import '../data/database/light_table_database.dart';
import '../data/repositories/sqlite_period_repository.dart';
import '../data/repositories/sqlite_schedule_repository.dart';
import '../domain/repositories/period_repository.dart';
import '../domain/repositories/schedule_repository.dart';

final class AppDependencies {
  AppDependencies({
    required this.scheduleRepository,
    required this.periodRepository,
  });

  factory AppDependencies.production() {
    final database = LightTableDatabase.shared;
    return AppDependencies(
      scheduleRepository: SqliteScheduleRepository(database),
      periodRepository: SqlitePeriodRepository(database),
    );
  }

  final ScheduleRepository scheduleRepository;
  final PeriodRepository periodRepository;
}
