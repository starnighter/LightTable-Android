import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lighttable/app/app_dependencies.dart';
import 'package:lighttable/data/database/light_table_database.dart';
import 'package:lighttable/data/repositories/sqlite_period_repository.dart';
import 'package:lighttable/data/repositories/sqlite_schedule_repository.dart';
import 'package:lighttable/domain/models/course.dart';
import 'package:lighttable/domain/models/schedule_import.dart';
import 'package:lighttable/main.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete timetable management flow persists on Android', (
    tester,
  ) async {
    final databasePath = path.join(
      await getDatabasesPath(),
      'lighttable-integration-test.db',
    );
    await databaseFactory.deleteDatabase(databasePath);

    final database = LightTableDatabase(databasePath: databasePath);
    final schedules = SqliteScheduleRepository(database);
    final periods = SqlitePeriodRepository(database);
    addTearDown(() async {
      await database.close();
      await databaseFactory.deleteDatabase(databasePath);
    });

    await schedules.importSchedule(
      ScheduleImport(
        term: '2026-2027-1',
        courses: [
          CourseDraft(
            name: '脱敏高等数学',
            location: 'A101',
            teacher: '测试教师',
            weekInterval: const [1, 2, 3],
            weekday: 2,
            periods: const [1, 2],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      LightTableApp(
        dependencies: AppDependencies(
          scheduleRepository: schedules,
          periodRepository: periods,
        ),
        now: () => DateTime(2026, 9, 7, 8, 30),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('第 2 周'), findsOneWidget);
    expect(find.text('脱敏高等数学'), findsOneWidget);

    await tester.tap(find.text('脱敏高等数学'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('course-name-field')), '线性代数');
    await tester.enterText(
      find.byKey(const Key('course-location-field')),
      'B202',
    );
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await tester.pumpAndSettle();
    final saveCourseButton = find.byKey(const Key('save-course-button'));
    await tester.ensureVisible(saveCourseButton);
    await tester.tap(saveCourseButton);
    await tester.pumpAndSettle();

    expect(find.text('线性代数'), findsOneWidget);
    var storedCourse = (await schedules.getCourses(
      (await schedules.getSelectedSchedule())!.id,
    )).single;
    expect(storedCourse.name, '线性代数');
    expect(storedCourse.location, 'B202');

    await tester.tap(find.byKey(const Key('home-schedule-settings')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('schedule-name-field')),
      '集成测试课表',
    );
    await tester.tap(find.byKey(const Key('save-schedule-button')));
    await tester.pumpAndSettle();
    expect((await schedules.getSelectedSchedule())!.name, '集成测试课表');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-navigation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-schedule-management')));
    await tester.pumpAndSettle();
    expect(find.text('集成测试课表'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-period-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-period-button')));
    await tester.pumpAndSettle();
    expect(await periods.getPeriods(), hasLength(11));
    await tester.tap(find.byKey(const Key('delete-last-period-button')));
    await tester.pumpAndSettle();
    expect(await periods.getPeriods(), hasLength(10));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-about')));
    await tester.pumpAndSettle();
    expect(find.text('yangpixi / LightTable'), findsOneWidget);
    await tester.tap(find.text('GNU General Public License v3.0'));
    await tester.pumpAndSettle();
    expect(find.textContaining('GNU GENERAL PUBLIC LICENSE'), findsOneWidget);

    storedCourse = (await schedules.getCourses(
      (await schedules.getSelectedSchedule())!.id,
    )).single;
    expect(storedCourse.name, '线性代数');
  });
}
