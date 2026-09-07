package com.yangpixi.lighttable.widget

import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteException
import java.io.File
import java.time.Clock
import java.time.DateTimeException
import java.time.LocalDate
import java.time.LocalDateTime

internal class LightTableWidgetRepository(
    context: Context,
    private val databaseFile: File = context.getDatabasePath(DATABASE_NAME),
    private val clock: Clock = Clock.systemDefaultZone(),
) {
    fun load(): WidgetState {
        if (!databaseFile.isFile) return WidgetState.DatabaseUnavailable
        return try {
            SQLiteDatabase.openDatabase(
                databaseFile.absolutePath,
                null,
                SQLiteDatabase.OPEN_READONLY or SQLiteDatabase.NO_LOCALIZED_COLLATORS,
            ).use(::readState)
        } catch (_: SQLiteException) {
            WidgetState.DatabaseUnavailable
        } catch (_: IllegalArgumentException) {
            WidgetState.DatabaseUnavailable
        } catch (_: DateTimeException) {
            WidgetState.DatabaseUnavailable
        }
    }

    private fun readState(database: SQLiteDatabase): WidgetState {
        val now = LocalDateTime.now(clock)
        val schedule = readSelectedSchedule(database)
            ?: return WidgetState.NoSchedule(now.toLocalDate())
        val week = WidgetScheduleCalculator.weekForDate(now.toLocalDate(), schedule)
            ?: return WidgetState.OutsideTerm(now.toLocalDate())
        val courses = readCourses(
            database = database,
            scheduleId = schedule.id,
            week = week,
            weekday = WidgetScheduleCalculator.databaseWeekday(now.toLocalDate()),
        )
        return WidgetScheduleCalculator.stateFor(now, schedule, courses)
    }

    private fun readSelectedSchedule(database: SQLiteDatabase): WidgetSchedule? {
        return database.rawQuery(
            """
            SELECT s.id, s.total_weeks, s.start_date
            FROM schedules s
            JOIN app_settings settings ON settings.value = s.id
            WHERE settings.key = ?
            LIMIT 1
            """.trimIndent(),
            arrayOf(SELECTED_SCHEDULE_KEY),
        ).use { cursor ->
            if (!cursor.moveToFirst()) return@use null
            WidgetSchedule(
                id = cursor.getString(cursor.getColumnIndexOrThrow("id")),
                totalWeeks = cursor.getInt(cursor.getColumnIndexOrThrow("total_weeks")),
                startDate = LocalDate.parse(
                    cursor.getString(cursor.getColumnIndexOrThrow("start_date")),
                ),
            )
        }
    }

    private fun readCourses(
        database: SQLiteDatabase,
        scheduleId: String,
        week: Int,
        weekday: Int,
    ): List<WidgetCourse> {
        return database.rawQuery(
            """
            SELECT
                c.id,
                c.name,
                c.location,
                c.teacher,
                MIN(cp.period_number) AS first_period,
                MAX(cp.period_number) AS last_period,
                MIN(p.start_minutes) AS start_minutes,
                MAX(p.end_minutes) AS end_minutes
            FROM courses c
            JOIN course_weeks cw ON cw.course_id = c.id
            JOIN course_periods cp ON cp.course_id = c.id
            JOIN periods p ON p.period_number = cp.period_number
            WHERE c.schedule_id = ?
              AND cw.week_number = ?
              AND c.weekday = ?
            GROUP BY c.id, c.name, c.location, c.teacher
            ORDER BY start_minutes ASC, end_minutes ASC, c.name ASC
            """.trimIndent(),
            arrayOf(scheduleId, week.toString(), weekday.toString()),
        ).use { cursor ->
            buildList {
                while (cursor.moveToNext()) add(cursor.toWidgetCourse())
            }
        }
    }

    private fun Cursor.toWidgetCourse(): WidgetCourse = WidgetCourse(
        id = getString(getColumnIndexOrThrow("id")),
        name = getString(getColumnIndexOrThrow("name")),
        location = getString(getColumnIndexOrThrow("location")),
        teacher = getString(getColumnIndexOrThrow("teacher")),
        firstPeriod = getInt(getColumnIndexOrThrow("first_period")),
        lastPeriod = getInt(getColumnIndexOrThrow("last_period")),
        startMinutes = getInt(getColumnIndexOrThrow("start_minutes")),
        endMinutes = getInt(getColumnIndexOrThrow("end_minutes")),
    )

    private companion object {
        const val DATABASE_NAME = "lighttable.db"
        const val SELECTED_SCHEDULE_KEY = "selected_schedule_id"
    }
}
