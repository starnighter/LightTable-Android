import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighttable/app/app_dependencies.dart';
import 'package:lighttable/domain/models/course.dart';
import 'package:lighttable/domain/models/period.dart';
import 'package:lighttable/domain/models/schedule.dart';
import 'package:lighttable/domain/models/schedule_import.dart';
import 'package:lighttable/domain/repositories/period_repository.dart';
import 'package:lighttable/domain/repositories/schedule_repository.dart';
import 'package:lighttable/main.dart';

void main() {
  testWidgets('empty state guides import and bottom navigation works', (
    tester,
  ) async {
    final harness = await _Harness.create();
    addTearDown(harness.close);

    await harness.pump(tester);

    expect(find.text('还没有课表'), findsOneWidget);
    expect(find.byKey(const Key('home-navigation')), findsOneWidget);
    expect(find.byKey(const Key('settings-navigation')), findsOneWidget);

    await tester.tap(find.byKey(const Key('import-guidance-button')));
    await tester.pumpAndSettle();
    expect(find.text('选择课表来源'), findsOneWidget);
    expect(find.byKey(const Key('school-Csu')), findsOneWidget);
    expect(find.text('中南大学'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-navigation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-list')), findsOneWidget);
    expect(find.text('课表管理'), findsOneWidget);
    expect(find.text('节次时间'), findsOneWidget);
  });

  testWidgets('timetable opens editor and persists course changes', (
    tester,
  ) async {
    final harness = await _Harness.create(seedSchedules: 1);
    addTearDown(harness.close);

    await harness.pump(tester);
    expect(
      tester
          .widget<PageView>(find.byKey(const Key('week-page-view')))
          .allowImplicitScrolling,
      isTrue,
    );
    expect(find.text('第 1 周'), findsOneWidget);
    expect(find.text('高等数学'), findsOneWidget);
    expect(find.byKey(const Key('course-course-1')), findsOneWidget);
    final courseHeight = tester
        .getSize(find.byKey(const Key('course-course-1')))
        .height;
    expect(courseHeight, inInclusiveRange(52, 108));
    expect(find.byKey(const Key('today-date')), findsOneWidget);

    await tester.fling(
      find.byKey(const Key('week-page-view')),
      const Offset(-700, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(find.text('第 2 周'), findsOneWidget);
    await tester.fling(
      find.byKey(const Key('week-page-view')),
      const Offset(700, 0),
      1200,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('course-course-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('course-name-field')), '线性代数');
    await tester.enterText(
      find.byKey(const Key('course-teacher-field')),
      '赵老师',
    );
    await tester.enterText(
      find.byKey(const Key('course-location-field')),
      'C303',
    );
    await tester.tap(find.byKey(const Key('course-start-period')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('第 2 节').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('course-end-period-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('第 3 节').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-course-button')));
    await tester.pumpAndSettle();

    expect(find.text('线性代数'), findsOneWidget);
    final selected = await harness.scheduleRepository.getSelectedSchedule();
    final course = (await harness.scheduleRepository.getCourses(selected!.id))
        .single;
    expect(course.name, '线性代数');
    expect(course.teacher, '赵老师');
    expect(course.location, 'C303');
    expect(course.periods, [2, 3]);
  });

  testWidgets('return-to-current-week button jumps back immediately', (
    tester,
  ) async {
    final harness = await _Harness.create(seedSchedules: 1);
    addTearDown(harness.close);
    await harness.pump(tester);

    await tester.fling(
      find.byKey(const Key('week-page-view')),
      const Offset(-700, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(find.text('第 2 周'), findsOneWidget);

    await tester.tap(find.byKey(const Key('return-to-current-week')));
    await tester.pumpAndSettle();
    expect(find.text('第 1 周'), findsOneWidget);
  });

  testWidgets('editing a date moves only the tapped course occurrence', (
    tester,
  ) async {
    final harness = await _Harness.create(seedSchedules: 1);
    addTearDown(harness.close);
    await harness.pump(tester);

    await tester.tap(find.byKey(const Key('course-course-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('course-date-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4').last);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-course-button')));
    await tester.pumpAndSettle();

    final schedule = await harness.scheduleRepository.getSelectedSchedule();
    final courses = await harness.scheduleRepository.getCourses(schedule!.id);
    expect(courses, hasLength(2));
    final recurring = courses.singleWhere((item) => item.id == 'course-1');
    final moved = courses.singleWhere((item) => item.id != 'course-1');
    expect(recurring.weekInterval, [2, 3]);
    expect(recurring.weekday, 2);
    expect(moved.weekInterval, [1]);
    expect(moved.weekday, 4);
  });

  testWidgets('tapping an empty slot adds a one-date course', (tester) async {
    final harness = await _Harness.create(seedSchedules: 1);
    addTearDown(harness.close);
    await harness.pump(tester);

    final emptyLayer = find.byKey(const ValueKey('empty-slots-layer-1'));
    expect(emptyLayer, findsOneWidget);
    final layerRect = tester.getRect(emptyLayer);
    final dayWidth = layerRect.width / 7;
    final periodHeight = layerRect.height / 10;
    await tester.tapAt(
      Offset(
        layerRect.left + dayWidth * 2.5,
        layerRect.top + periodHeight * 3.5,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('添加课程'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('course-name-field')), '临时加课');
    await tester.tap(find.byKey(const Key('save-course-button')));
    await tester.pumpAndSettle();

    expect(find.text('临时加课'), findsOneWidget);
    final schedule = await harness.scheduleRepository.getSelectedSchedule();
    final added = (await harness.scheduleRepository.getCourses(schedule!.id))
        .singleWhere((course) => course.name == '临时加课');
    expect(added.weekInterval, [1]);
    expect(added.weekday, 3);
    expect(added.periods, [4]);
  });

  testWidgets('empty slots use one lightweight hit layer per week', (
    tester,
  ) async {
    final harness = await _Harness.create(seedSchedules: 1);
    addTearDown(harness.close);
    await harness.pump(tester);

    expect(find.byKey(const ValueKey('empty-slots-layer-1')), findsOneWidget);
    expect(find.byKey(const Key('empty-slot-1-3-4')), findsNothing);

    await tester.fling(
      find.byKey(const Key('week-page-view')),
      const Offset(-700, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(find.text('第 2 周'), findsOneWidget);
    expect(find.byKey(const ValueKey('empty-slots-layer-2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule parameters can be edited and saved', (tester) async {
    final harness = await _Harness.create(seedSchedules: 1);
    addTearDown(harness.close);
    await harness.pump(tester);

    await tester.tap(find.byKey(const Key('home-schedule-settings')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('schedule-name-field')),
      '春季课表',
    );
    await tester.tap(find.byKey(const Key('increase-weeks')));
    await tester.tap(find.byKey(const Key('start-date-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-schedule-button')));
    await tester.pumpAndSettle();

    expect(find.text('已保存'), findsOneWidget);
    final schedule = await harness.scheduleRepository.getSelectedSchedule();
    expect(schedule!.name, '春季课表');
    expect(schedule.totalWeeks, 21);
    expect(schedule.startDate, DateTime(2026, 3, 15));
  });

  testWidgets('schedule selection and selected-schedule fallback work', (
    tester,
  ) async {
    final harness = await _Harness.create(seedSchedules: 2);
    addTearDown(harness.close);
    await harness.pump(tester);

    await tester.tap(find.byKey(const Key('settings-navigation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-schedule-management')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('schedule-schedule-0')));
    await tester.pumpAndSettle();
    expect(
      (await harness.scheduleRepository.getSelectedSchedule())!.id,
      'schedule-0',
    );

    await tester.tap(find.byKey(const Key('delete-schedule-schedule-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-schedule')));
    await tester.pumpAndSettle();

    expect(find.text('课表已删除'), findsOneWidget);
    expect(
      (await harness.scheduleRepository.getSelectedSchedule())!.id,
      'schedule-2',
    );
  });

  testWidgets('period list supports adding and deleting its last item', (
    tester,
  ) async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    await harness.pump(tester);

    await tester.tap(find.byKey(const Key('settings-navigation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-period-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('period-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-period-button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('period-11')),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const Key('period-11')), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-last-period-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('period-11')), findsNothing);
    expect(await harness.periodRepository.getPeriods(), hasLength(10));
  });

  testWidgets('about and GPL license pages support back navigation', (
    tester,
  ) async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    await harness.pump(tester);

    await tester.tap(find.byKey(const Key('settings-navigation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-about')));
    await tester.pumpAndSettle();
    expect(find.text('yangpixi / LightTable'), findsOneWidget);

    await tester.tap(find.text('GNU General Public License v3.0'));
    await tester.pumpAndSettle();
    expect(find.textContaining('GNU GENERAL PUBLIC LICENSE'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('yangpixi / LightTable'), findsOneWidget);
  });

  testWidgets('overlapping courses in the same week use separate lanes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _Harness.create(
      seedSchedules: 1,
      seedOverlappingCourses: true,
    );
    addTearDown(harness.close);

    await harness.pump(tester);
    final first = tester.getRect(find.byKey(const Key('course-course-1')));
    final second = tester.getRect(
      find.byKey(const Key('course-course-overlap')),
    );

    expect((first.top - second.top).abs(), lessThan(0.1));
    expect(
      first.right <= second.left + 0.1 || second.right <= first.left + 0.1,
      isTrue,
    );
  });

  testWidgets('odd and even week courses occupy the same slot separately', (
    tester,
  ) async {
    final harness = await _Harness.create(
      seedSchedules: 1,
      seedAlternatingCourses: true,
    );
    addTearDown(harness.close);

    await harness.pump(tester);
    expect(find.text('单周课程'), findsOneWidget);
    expect(find.text('双周课程'), findsNothing);

    await tester.fling(
      find.byKey(const Key('week-page-view')),
      const Offset(-700, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(find.text('单周课程'), findsNothing);
    expect(find.text('双周课程'), findsOneWidget);
  });

  testWidgets('twelve periods fit a normal portrait page without scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _Harness.create(seedSchedules: 1);
    addTearDown(harness.close);
    await harness.periodRepository.addPeriod();
    await harness.periodRepository.addPeriod();

    await harness.pump(tester);
    final weekScroll = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('week-scroll-1')),
    );
    expect(weekScroll.physics, isA<NeverScrollableScrollPhysics>());
    expect(
      tester.getBottomRight(find.byKey(const Key('timetable-period-12'))).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy + 0.5),
    );
  });

  for (final variant in <_DisplayVariant>[
    const _DisplayVariant('small portrait', Size(320, 568)),
    const _DisplayVariant('landscape', Size(800, 400)),
    const _DisplayVariant('large text', Size(400, 800), textScale: 2),
    const _DisplayVariant('dark mode', Size(400, 800), dark: true),
  ]) {
    testWidgets('timetable has no layout exception on ${variant.name}', (
      tester,
    ) async {
      tester.view.physicalSize = variant.size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = variant.textScale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final harness = await _Harness.create(seedSchedules: 1);
      addTearDown(harness.close);

      await harness.pump(tester, dark: variant.dark);
      expect(find.byKey(const Key('week-page-view')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

final class _Harness {
  _Harness({required this.scheduleRepository, required this.periodRepository});

  static Future<_Harness> create({
    int seedSchedules = 0,
    bool seedOverlappingCourses = false,
    bool seedAlternatingCourses = false,
  }) async {
    final schedules = _FakeScheduleRepository();
    final periods = _FakePeriodRepository();
    for (var index = 0; index < seedSchedules; index++) {
      final schedule = Schedule(
        id: 'schedule-${index * 2}',
        name: '课表 ${index + 1}',
        totalWeeks: 20,
        startDate: DateTime(2026, 3, 1),
        createdAt: DateTime(2026, 2, 1, 0, index),
      );
      schedules.add(
        schedule,
        Course(
          id: 'course-${index * 2 + 1}',
          scheduleId: schedule.id,
          name: index == 0
              ? (seedAlternatingCourses ? '单周课程' : '高等数学')
              : '大学英语',
          location: index == 0 ? 'A101' : 'B202',
          teacher: index == 0 ? '王老师' : '李老师',
          weekInterval: index == 0 && seedAlternatingCourses
              ? const [1, 3]
              : const [1, 2, 3],
          weekday: index == 0 ? 2 : 3,
          periods: const [1, 2],
        ),
      );
      if (index == 0 && seedOverlappingCourses) {
        schedules.seedCourse(
          Course(
            id: 'course-overlap',
            scheduleId: schedule.id,
            name: '大学英语',
            location: 'B202',
            teacher: '李老师',
            weekInterval: const [1, 2, 3],
            weekday: 2,
            periods: const [1, 2],
          ),
        );
      }
      if (index == 0 && seedAlternatingCourses) {
        schedules.seedCourse(
          Course(
            id: 'course-even',
            scheduleId: schedule.id,
            name: '双周课程',
            location: 'B502',
            teacher: '双周教师',
            weekInterval: const [2],
            weekday: 2,
            periods: const [1, 2],
          ),
        );
      }
    }
    return _Harness(scheduleRepository: schedules, periodRepository: periods);
  }

  final _FakeScheduleRepository scheduleRepository;
  final _FakePeriodRepository periodRepository;

  Future<void> pump(WidgetTester tester, {bool dark = false}) async {
    await tester.pumpWidget(
      LightTableApp(
        dependencies: AppDependencies(
          scheduleRepository: scheduleRepository,
          periodRepository: periodRepository,
        ),
        now: () => DateTime(2026, 3, 2, 9),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> close() async {}
}

final class _FakeScheduleRepository implements ScheduleRepository {
  final List<Schedule> _schedules = [];
  final Map<String, List<Course>> _courses = {};
  String? _selectedId;
  var _nextCourseId = 0;

  void add(Schedule schedule, Course course) {
    _schedules.add(schedule);
    _courses[schedule.id] = [course];
    _selectedId = schedule.id;
  }

  void seedCourse(Course course) {
    _courses.putIfAbsent(course.scheduleId, () => []).add(course);
  }

  @override
  Future<Course> addCourse(String scheduleId, CourseDraft draft) async {
    final course = draft.toCourse(
      id: 'manual-${_nextCourseId++}',
      scheduleId: scheduleId,
    );
    _courses.putIfAbsent(scheduleId, () => []).add(course);
    return course;
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    _schedules.removeWhere((schedule) => schedule.id == scheduleId);
    _courses.remove(scheduleId);
    if (_selectedId == scheduleId) {
      _schedules.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _selectedId = _schedules.firstOrNull?.id;
    }
  }

  @override
  Future<List<Course>> getCourses(String scheduleId) async {
    return List.unmodifiable(_courses[scheduleId] ?? const []);
  }

  @override
  Future<Schedule?> getSchedule(String id) async {
    return _schedules.where((schedule) => schedule.id == id).firstOrNull;
  }

  @override
  Future<List<Schedule>> getSchedules() async => List.unmodifiable(_schedules);

  @override
  Future<Schedule?> getSelectedSchedule() async {
    final id = _selectedId;
    return id == null ? null : getSchedule(id);
  }

  @override
  Future<String?> getSelectedScheduleId() async => _selectedId;

  @override
  Future<Schedule> importSchedule(ScheduleImport data) {
    throw UnimplementedError();
  }

  @override
  Future<void> selectSchedule(String? scheduleId) async {
    _selectedId = scheduleId;
  }

  @override
  Future<void> updateCourse(Course course) async {
    final courses = _courses[course.scheduleId]!;
    courses[courses.indexWhere((item) => item.id == course.id)] = course;
  }

  @override
  Future<void> updateCourseOccurrence({
    required Course course,
    required int sourceWeek,
    required int targetWeek,
    required int targetWeekday,
  }) async {
    final courses = _courses[course.scheduleId]!;
    final index = courses.indexWhere((item) => item.id == course.id);
    final stored = courses[index];
    if (sourceWeek == targetWeek && stored.weekday == targetWeekday) {
      courses[index] = course.copyWith(weekInterval: stored.weekInterval);
      return;
    }
    if (stored.weekInterval.length == 1) {
      courses[index] = course.copyWith(
        weekInterval: [targetWeek],
        weekday: targetWeekday,
      );
      return;
    }
    courses[index] = course.copyWith(
      weekInterval: stored.weekInterval
          .where((week) => week != sourceWeek)
          .toList(),
      weekday: stored.weekday,
    );
    courses.add(
      Course(
        id: 'manual-${_nextCourseId++}',
        scheduleId: course.scheduleId,
        name: course.name,
        location: course.location,
        teacher: course.teacher,
        weekInterval: [targetWeek],
        weekday: targetWeekday,
        periods: course.periods,
      ),
    );
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    _schedules[_schedules.indexWhere((item) => item.id == schedule.id)] =
        schedule;
  }
}

final class _FakePeriodRepository implements PeriodRepository {
  final List<Period> _periods = [
    for (var number = 1; number <= 10; number++)
      Period(
        number: number,
        startMinutes: 8 * 60 + (number - 1) * 60,
        endMinutes: 8 * 60 + (number - 1) * 60 + 45,
      ),
  ];

  @override
  Future<Period> addPeriod() async {
    final last = _periods.last;
    final period = Period(
      number: last.number + 1,
      startMinutes: last.endMinutes + 10,
      endMinutes: last.endMinutes + 55,
    );
    _periods.add(period);
    return period;
  }

  @override
  Future<void> deleteLastPeriod() async {
    _periods.removeLast();
  }

  @override
  Future<List<Period>> getPeriods() async => List.unmodifiable(_periods);

  @override
  Future<void> updatePeriod(Period period) async {
    _periods[_periods.indexWhere((item) => item.number == period.number)] =
        period;
  }
}

final class _DisplayVariant {
  const _DisplayVariant(
    this.name,
    this.size, {
    this.textScale = 1,
    this.dark = false,
  });

  final String name;
  final Size size;
  final double textScale;
  final bool dark;
}
