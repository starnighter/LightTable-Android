package com.yangpixi.lighttable.widget

import java.time.LocalDate
import java.time.LocalDateTime
import java.time.temporal.ChronoUnit

internal data class WidgetSchedule(
    val id: String,
    val totalWeeks: Int,
    val startDate: LocalDate,
)

internal data class WidgetCourse(
    val id: String,
    val name: String,
    val location: String,
    val teacher: String,
    val firstPeriod: Int,
    val lastPeriod: Int,
    val startMinutes: Int,
    val endMinutes: Int,
) {
    val periodLabel: String
        get() = if (firstPeriod == lastPeriod) {
            "第${firstPeriod}节"
        } else {
            "第${firstPeriod}-${lastPeriod}节"
        }

    val timeLabel: String
        get() = "${formatMinutes(startMinutes)}-${formatMinutes(endMinutes)}"

    private fun formatMinutes(minutes: Int): String =
        "%02d:%02d".format(minutes / 60, minutes % 60)
}

internal sealed interface WidgetState {
    data object DatabaseUnavailable : WidgetState

    data class NoSchedule(val date: LocalDate) : WidgetState

    data class OutsideTerm(val date: LocalDate) : WidgetState

    data class NoCourses(
        val date: LocalDate,
        val week: Int,
    ) : WidgetState

    data class FinishedForToday(
        val date: LocalDate,
        val week: Int,
    ) : WidgetState

    data class Courses(
        val date: LocalDate,
        val week: Int,
        val primary: WidgetCourse,
        val secondary: WidgetCourse?,
        val primaryIsOngoing: Boolean,
    ) : WidgetState
}

internal object WidgetScheduleCalculator {
    fun weekForDate(date: LocalDate, schedule: WidgetSchedule): Int? {
        val firstSunday = schedule.startDate.minusDays(
            (schedule.startDate.dayOfWeek.value % 7).toLong(),
        )
        val targetSunday = date.minusDays((date.dayOfWeek.value % 7).toLong())
        val week = ChronoUnit.WEEKS.between(firstSunday, targetSunday).toInt() + 1
        return week.takeIf { it in 1..schedule.totalWeeks }
    }

    fun stateFor(
        now: LocalDateTime,
        schedule: WidgetSchedule,
        courses: List<WidgetCourse>,
    ): WidgetState {
        val date = now.toLocalDate()
        val week = weekForDate(date, schedule) ?: return WidgetState.OutsideTerm(date)
        if (courses.isEmpty()) return WidgetState.NoCourses(date, week)

        val sortedCourses = courses.sortedWith(
            compareBy<WidgetCourse> { it.startMinutes }
                .thenBy { it.endMinutes }
                .thenBy { it.name },
        )
        val nowMinutes = now.hour * 60 + now.minute
        val ongoing = sortedCourses.firstOrNull {
            nowMinutes >= it.startMinutes && nowMinutes < it.endMinutes
        }
        if (ongoing != null) {
            return WidgetState.Courses(
                date = date,
                week = week,
                primary = ongoing,
                secondary = sortedCourses.firstOrNull {
                    it.id != ongoing.id && it.startMinutes > nowMinutes
                },
                primaryIsOngoing = true,
            )
        }

        val upcoming = sortedCourses.filter { it.startMinutes > nowMinutes }
        if (upcoming.isEmpty()) return WidgetState.FinishedForToday(date, week)
        return WidgetState.Courses(
            date = date,
            week = week,
            primary = upcoming.first(),
            secondary = upcoming.getOrNull(1),
            primaryIsOngoing = false,
        )
    }

    fun databaseWeekday(date: LocalDate): Int = date.dayOfWeek.value % 7 + 1
}
