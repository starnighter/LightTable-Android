package com.yangpixi.lighttable.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate
import java.time.LocalDateTime

class WidgetScheduleCalculatorTest {
    private val schedule = WidgetSchedule(
        id = "schedule",
        totalWeeks = 20,
        startDate = LocalDate.of(2025, 12, 31),
    )

    @Test
    fun `week one is the Sunday-to-Saturday week containing start date`() {
        assertEquals(
            1,
            WidgetScheduleCalculator.weekForDate(LocalDate.of(2025, 12, 28), schedule),
        )
        assertEquals(
            1,
            WidgetScheduleCalculator.weekForDate(LocalDate.of(2026, 1, 3), schedule),
        )
        assertEquals(
            2,
            WidgetScheduleCalculator.weekForDate(LocalDate.of(2026, 1, 4), schedule),
        )
        assertNull(
            WidgetScheduleCalculator.weekForDate(LocalDate.of(2025, 12, 27), schedule),
        )
        assertNull(
            WidgetScheduleCalculator.weekForDate(LocalDate.of(2026, 5, 17), schedule),
        )
    }

    @Test
    fun `ongoing course is primary and next course is secondary`() {
        val current = course("current", 1, 2, 8 * 60, 9 * 60 + 40)
        val next = course("next", 3, 4, 10 * 60, 11 * 60 + 40)
        val state = WidgetScheduleCalculator.stateFor(
            now = LocalDateTime.of(2025, 12, 29, 8, 30),
            schedule = schedule,
            courses = listOf(next, current),
        )

        assertTrue(state is WidgetState.Courses)
        state as WidgetState.Courses
        assertTrue(state.primaryIsOngoing)
        assertEquals("current", state.primary.id)
        assertEquals("next", state.secondary?.id)
    }

    @Test
    fun `without ongoing course only the next two courses are shown`() {
        val first = course("first", 1, 2, 8 * 60, 9 * 60 + 40)
        val second = course("second", 3, 4, 10 * 60, 11 * 60 + 40)
        val third = course("third", 5, 6, 14 * 60, 15 * 60 + 40)
        val state = WidgetScheduleCalculator.stateFor(
            now = LocalDateTime.of(2025, 12, 29, 7, 30),
            schedule = schedule,
            courses = listOf(third, first, second),
        ) as WidgetState.Courses

        assertTrue(!state.primaryIsOngoing)
        assertEquals("first", state.primary.id)
        assertEquals("second", state.secondary?.id)
    }

    @Test
    fun `empty, finished, and outside-term states are distinct`() {
        val inTerm = LocalDateTime.of(2025, 12, 29, 12, 0)
        assertTrue(
            WidgetScheduleCalculator.stateFor(inTerm, schedule, emptyList())
                is WidgetState.NoCourses,
        )
        assertTrue(
            WidgetScheduleCalculator.stateFor(
                inTerm,
                schedule,
                listOf(course("past", 1, 2, 8 * 60, 9 * 60 + 40)),
            ) is WidgetState.FinishedForToday,
        )
        assertTrue(
            WidgetScheduleCalculator.stateFor(
                LocalDateTime.of(2025, 12, 20, 8, 0),
                schedule,
                emptyList(),
            ) is WidgetState.OutsideTerm,
        )
    }

    @Test
    fun `database weekday matches Sunday-first schema`() {
        assertEquals(1, WidgetScheduleCalculator.databaseWeekday(LocalDate.of(2026, 9, 6)))
        assertEquals(2, WidgetScheduleCalculator.databaseWeekday(LocalDate.of(2026, 9, 7)))
        assertEquals(7, WidgetScheduleCalculator.databaseWeekday(LocalDate.of(2026, 9, 12)))
    }

    @Test
    fun `crossing midnight recalculates date week and upcoming courses`() {
        val beforeMidnight = WidgetScheduleCalculator.stateFor(
            now = LocalDateTime.of(2026, 1, 3, 23, 59),
            schedule = schedule,
            courses = listOf(course("saturday", 9, 10, 19 * 60, 20 * 60 + 40)),
        )
        val afterMidnight = WidgetScheduleCalculator.stateFor(
            now = LocalDateTime.of(2026, 1, 4, 0, 0),
            schedule = schedule,
            courses = listOf(course("sunday", 1, 2, 8 * 60, 9 * 60 + 40)),
        ) as WidgetState.Courses

        assertTrue(beforeMidnight is WidgetState.FinishedForToday)
        assertEquals(LocalDate.of(2026, 1, 4), afterMidnight.date)
        assertEquals(2, afterMidnight.week)
        assertEquals("sunday", afterMidnight.primary.id)
        assertTrue(!afterMidnight.primaryIsOngoing)
    }

    private fun course(
        id: String,
        firstPeriod: Int,
        lastPeriod: Int,
        startMinutes: Int,
        endMinutes: Int,
    ) = WidgetCourse(
        id = id,
        name = "课程$id",
        location = "A101",
        teacher = "教师",
        firstPeriod = firstPeriod,
        lastPeriod = lastPeriod,
        startMinutes = startMinutes,
        endMinutes = endMinutes,
    )
}
