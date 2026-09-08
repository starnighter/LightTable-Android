import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/course.dart';
import '../../domain/models/period.dart';
import '../../domain/models/schedule.dart';
import '../../domain/utils/schedule_date_utils.dart';
import '../../l10n/generated/app_localizations.dart';
import '../utils/ui_formatters.dart';

typedef CourseTapCallback = void Function(Course course, int week);
typedef EmptySlotTapCallback = void Function(int week, int weekday, int period);

class Timetable extends StatefulWidget {
  const Timetable({
    required this.schedule,
    required this.courses,
    required this.periods,
    required this.now,
    required this.onCourseTap,
    required this.onEmptySlotTap,
    super.key,
  });

  final Schedule schedule;
  final List<Course> courses;
  final List<Period> periods;
  final DateTime Function() now;
  final CourseTapCallback onCourseTap;
  final EmptySlotTapCallback onEmptySlotTap;

  @override
  State<Timetable> createState() => _TimetableState();
}

class _TimetableState extends State<Timetable> {
  late PageController _pageController;
  late final ValueNotifier<int> _week;
  late List<List<_CoursePlacement>> _placementsByWeek;

  @override
  void initState() {
    super.initState();
    final initialWeek = UiFormatters.initialWeek(widget.now(), widget.schedule);
    _week = ValueNotifier(initialWeek);
    _pageController = PageController(initialPage: initialWeek - 1);
    _cacheWeekPlacements();
  }

  @override
  void didUpdateWidget(covariant Timetable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.courses, widget.courses) ||
        oldWidget.schedule.totalWeeks != widget.schedule.totalWeeks) {
      _cacheWeekPlacements();
    }
    if (oldWidget.schedule.startDate != widget.schedule.startDate ||
        oldWidget.schedule.totalWeeks != widget.schedule.totalWeeks) {
      final initialWeek = UiFormatters.initialWeek(
        widget.now(),
        widget.schedule,
      );
      _week.value = initialWeek;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(initialWeek - 1);
        }
      });
    }
  }

  void _cacheWeekPlacements() {
    final coursesByWeek = List.generate(
      widget.schedule.totalWeeks,
      (_) => <Course>[],
      growable: false,
    );
    for (final course in widget.courses) {
      for (final week in course.weekInterval) {
        if (week <= coursesByWeek.length) coursesByWeek[week - 1].add(course);
      }
    }
    _placementsByWeek = coursesByWeek
        .map(
          (courses) =>
              List<_CoursePlacement>.unmodifiable(_placeCourses(courses)),
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _week.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentWeek = ScheduleDateUtils.weekForDate(
      widget.now(),
      widget.schedule,
    );
    return Column(
      children: [
        ValueListenableBuilder<int>(
          valueListenable: _week,
          builder: (context, week, _) => _WeekHeader(
            week: week,
            currentWeek: currentWeek,
            onReturnToCurrentWeek: currentWeek == null || currentWeek == week
                ? null
                : () => _pageController.animateToPage(
                    currentWeek - 1,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                  ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            key: const Key('week-page-view'),
            controller: _pageController,
            itemCount: widget.schedule.totalWeeks,
            allowImplicitScrolling: true,
            onPageChanged: (index) => _week.value = index + 1,
            itemBuilder: (context, index) => _WeekPage(
              key: ValueKey('timetable-week-${index + 1}'),
              week: index + 1,
              schedule: widget.schedule,
              placements: _placementsByWeek[index],
              periods: widget.periods,
              today: widget.now(),
              onCourseTap: widget.onCourseTap,
              onEmptySlotTap: widget.onEmptySlotTap,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.week,
    required this.currentWeek,
    required this.onReturnToCurrentWeek,
  });

  final int week;
  final int? currentWeek;
  final VoidCallback? onReturnToCurrentWeek;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
      child: Row(
        children: [
          Text(
            strings.weekTitle(week),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (currentWeek != week) ...[
            const SizedBox(width: 8),
            Text(
              strings.notCurrentWeek,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            key: const Key('return-to-current-week'),
            tooltip: strings.returnToCurrentWeek,
            onPressed: onReturnToCurrentWeek,
            icon: const Icon(Icons.today_outlined),
          ),
        ],
      ),
    );
  }
}

class _WeekPage extends StatefulWidget {
  const _WeekPage({
    required this.week,
    required this.schedule,
    required this.placements,
    required this.periods,
    required this.today,
    required this.onCourseTap,
    required this.onEmptySlotTap,
    super.key,
  });

  final int week;
  final Schedule schedule;
  final List<_CoursePlacement> placements;
  final List<Period> periods;
  final DateTime today;
  final CourseTapCallback onCourseTap;
  final EmptySlotTapCallback onEmptySlotTap;

  static const headerHeight = 56.0;
  static const minPeriodHeight = 32.0;
  static const maxPeriodHeight = 58.0;
  static const periodWidth = 52.0;

  @override
  State<_WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends State<_WeekPage>
    with AutomaticKeepAliveClientMixin<_WeekPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(constraints.maxWidth, 300.0);
        final dayWidth = (width - _WeekPage.periodWidth) / 7;
        final availablePeriodHeight = widget.periods.isEmpty
            ? _WeekPage.maxPeriodHeight
            : (constraints.maxHeight - _WeekPage.headerHeight) /
                  widget.periods.length;
        final periodHeight = availablePeriodHeight
            .clamp(_WeekPage.minPeriodHeight, _WeekPage.maxPeriodHeight)
            .toDouble();
        final height =
            _WeekPage.headerHeight + widget.periods.length * periodHeight;
        return SingleChildScrollView(
          key: ValueKey('week-scroll-${widget.week}'),
          physics: height <= constraints.maxHeight + 0.5
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                _Grid(
                  week: widget.week,
                  schedule: widget.schedule,
                  periods: widget.periods,
                  today: widget.today,
                  dayWidth: dayWidth,
                  periodHeight: periodHeight,
                ),
                _EmptySlotsLayer(
                  week: widget.week,
                  periods: widget.periods,
                  dayWidth: dayWidth,
                  periodHeight: periodHeight,
                  onTap: (weekday, period) {
                    if (!_isOccupied(weekday, period)) {
                      widget.onEmptySlotTap(widget.week, weekday, period);
                    }
                  },
                ),
                for (final placement in widget.placements)
                  _CourseBlock(
                    placement: placement,
                    dayWidth: dayWidth,
                    periodHeight: periodHeight,
                    onTap: () =>
                        widget.onCourseTap(placement.course, widget.week),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isOccupied(int weekday, int period) {
    return widget.placements.any(
      (placement) =>
          placement.course.weekday == weekday &&
          placement.course.periods.contains(period),
    );
  }
}

class _EmptySlotsLayer extends StatelessWidget {
  const _EmptySlotsLayer({
    required this.week,
    required this.periods,
    required this.dayWidth,
    required this.periodHeight,
    required this.onTap,
  });

  final int week;
  final List<Period> periods;
  final double dayWidth;
  final double periodHeight;
  final void Function(int weekday, int period) onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _WeekPage.periodWidth,
      top: _WeekPage.headerHeight,
      width: dayWidth * 7,
      height: periodHeight * periods.length,
      child: GestureDetector(
        key: ValueKey('empty-slots-layer-$week'),
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final weekday = details.localPosition.dx ~/ dayWidth + 1;
          final periodIndex = details.localPosition.dy ~/ periodHeight;
          if (weekday < 1 || weekday > 7) return;
          if (periodIndex < 0 || periodIndex >= periods.length) return;
          onTap(weekday, periods[periodIndex].number);
        },
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.week,
    required this.schedule,
    required this.periods,
    required this.today,
    required this.dayWidth,
    required this.periodHeight,
  });

  final int week;
  final Schedule schedule;
  final List<Period> periods;
  final DateTime today;
  final double dayWidth;
  final double periodHeight;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final weekdays = [
      strings.weekdaySunday,
      strings.weekdayMonday,
      strings.weekdayTuesday,
      strings.weekdayWednesday,
      strings.weekdayThursday,
      strings.weekdayFriday,
      strings.weekdaySaturday,
    ];
    final firstDate = ScheduleDateUtils.dateFor(
      schedule: schedule,
      week: week,
      weekday: 1,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _WeekPage.periodWidth,
          child: Column(
            children: [
              SizedBox(
                height: _WeekPage.headerHeight,
                child: Center(
                  child: Text(
                    strings.monthTitle(firstDate.month),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              for (final period in periods)
                SizedBox(
                  key: Key('timetable-period-${period.number}'),
                  height: periodHeight,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${period.number}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            period.startTime,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          Text(
                            period.endTime,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (var weekday = 1; weekday <= 7; weekday++)
          SizedBox(
            width: dayWidth,
            child: Column(
              children: [
                _DayHeader(
                  label: weekdays[weekday - 1],
                  date: ScheduleDateUtils.dateFor(
                    schedule: schedule,
                    week: week,
                    weekday: weekday,
                  ),
                  today: today,
                  height: _WeekPage.headerHeight,
                ),
                for (final _ in periods) SizedBox(height: periodHeight),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.label,
    required this.date,
    required this.today,
    required this.height,
  });

  final String label;
  final DateTime date;
  final DateTime today;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Container(
                key: isToday ? const Key('today-date') : null,
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday ? colors.primary : null,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isToday ? colors.onPrimary : colors.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.w700 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<_CoursePlacement> _placeCourses(List<Course> courses) {
  final sorted = [...courses]
    ..sort((left, right) {
      final byWeekday = left.weekday.compareTo(right.weekday);
      if (byWeekday != 0) return byWeekday;
      final byStart = left.firstPeriod.compareTo(right.firstPeriod);
      if (byStart != 0) return byStart;
      final byEnd = left.lastPeriod.compareTo(right.lastPeriod);
      if (byEnd != 0) return byEnd;
      final byName = left.name.compareTo(right.name);
      return byName != 0 ? byName : left.id.compareTo(right.id);
    });
  final result = <_CoursePlacement>[];
  var component = <Course>[];
  var componentWeekday = -1;
  var componentEnd = -1;

  void flushComponent() {
    if (component.isEmpty) return;
    result.addAll(_placeOverlappingComponent(component));
    component = <Course>[];
  }

  for (final course in sorted) {
    final startsNewComponent =
        component.isNotEmpty &&
        (course.weekday != componentWeekday ||
            course.firstPeriod > componentEnd);
    if (startsNewComponent) flushComponent();
    if (component.isEmpty) {
      componentWeekday = course.weekday;
      componentEnd = course.lastPeriod;
    } else {
      componentEnd = math.max(componentEnd, course.lastPeriod);
    }
    component.add(course);
  }
  flushComponent();
  return result;
}

List<_CoursePlacement> _placeOverlappingComponent(List<Course> courses) {
  final laneEnds = <int>[];
  final assigned = <({Course course, int lane})>[];
  for (final course in courses) {
    var lane = laneEnds.indexWhere((end) => end < course.firstPeriod);
    if (lane == -1) {
      lane = laneEnds.length;
      laneEnds.add(course.lastPeriod);
    } else {
      laneEnds[lane] = course.lastPeriod;
    }
    assigned.add((course: course, lane: lane));
  }
  return [
    for (final item in assigned)
      _CoursePlacement(
        course: item.course,
        lane: item.lane,
        laneCount: laneEnds.length,
      ),
  ];
}

final class _CoursePlacement {
  const _CoursePlacement({
    required this.course,
    required this.lane,
    required this.laneCount,
  });

  final Course course;
  final int lane;
  final int laneCount;
}

class _CourseBlock extends StatelessWidget {
  const _CourseBlock({
    required this.placement,
    required this.dayWidth,
    required this.periodHeight,
    required this.onTap,
  });

  final _CoursePlacement placement;
  final double dayWidth;
  final double periodHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final course = placement.course;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF174A73)
        : const Color(0xFFD7E9FF);
    final titleColor = isDark
        ? const Color(0xFFEAF3FF)
        : const Color(0xFF153F66);
    final detailColor = isDark
        ? const Color(0xFFB8D6F3)
        : const Color(0xFF527493);
    const horizontalInset = 3.0;
    const laneGap = 2.0;
    final availableWidth = math.max(dayWidth - horizontalInset * 2, 1.0);
    final laneWidth = math.max(
      (availableWidth - laneGap * (placement.laneCount - 1)) /
          placement.laneCount,
      1.0,
    );
    return Positioned(
      left:
          _WeekPage.periodWidth +
          (course.weekday - 1) * dayWidth +
          horizontalInset +
          placement.lane * (laneWidth + laneGap),
      top: _WeekPage.headerHeight + (course.firstPeriod - 1) * periodHeight + 4,
      width: laneWidth,
      height: course.periods.length * periodHeight - 8,
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('course-${course.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: math.max(laneWidth - 6, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (course.location.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        course.location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: detailColor),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
