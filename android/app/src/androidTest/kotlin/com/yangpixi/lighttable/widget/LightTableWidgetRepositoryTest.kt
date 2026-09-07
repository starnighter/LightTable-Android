package com.yangpixi.lighttable.widget

import android.database.sqlite.SQLiteDatabase
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.time.Clock
import java.time.Instant
import java.time.ZoneId

@RunWith(AndroidJUnit4::class)
class LightTableWidgetRepositoryTest {
    private val context = ApplicationProvider.getApplicationContext<android.content.Context>()
    private lateinit var databaseFile: File
    private val clock = Clock.fixed(
        Instant.parse("2026-09-07T00:30:00Z"),
        ZoneId.of("Asia/Shanghai"),
    )

    @Before
    fun setUp() {
        databaseFile = File(context.cacheDir, "widget-${System.nanoTime()}.db")
    }

    @After
    fun tearDown() {
        databaseFile.delete()
        File("${databaseFile.path}-wal").delete()
        File("${databaseFile.path}-shm").delete()
    }

    @Test
    fun missingDatabaseHasExplicitState() {
        val state = LightTableWidgetRepository(context, databaseFile, clock).load()
        assertEquals(WidgetState.DatabaseUnavailable, state)
    }

    @Test
    fun initializedDatabaseWithoutScheduleHasExplicitState() {
        createSchema().close()
        val state = LightTableWidgetRepository(context, databaseFile, clock).load()
        assertTrue(state is WidgetState.NoSchedule)
    }

    @Test
    fun readsSelectedScheduleCurrentCourseAndNextCourse() {
        createSchema().use { database ->
            insertSchedule(database, id = "old", selected = false)
            insertSchedule(database, id = "selected", selected = true)
            insertCourse(database, "current", "selected", 8 * 60, 9 * 60 + 40, 1, 2)
            insertCourse(database, "next", "selected", 10 * 60, 11 * 60 + 40, 3, 4)
            insertCourse(database, "ignored", "old", 8 * 60, 9 * 60 + 40, 1, 2)
        }

        val state = LightTableWidgetRepository(context, databaseFile, clock).load()
            as WidgetState.Courses
        assertEquals(1, state.week)
        assertEquals("current", state.primary.id)
        assertEquals("next", state.secondary?.id)
        assertTrue(state.primaryIsOngoing)
    }

    @Test
    fun scheduleOutsideTermHasExplicitState() {
        createSchema().use { database ->
            database.execSQL(
                "INSERT INTO schedules VALUES (?, ?, ?, ?, ?)",
                arrayOf<Any>("selected", "过期课表", 1, "2026-01-01", 1L),
            )
            database.execSQL(
                "INSERT INTO app_settings VALUES (?, ?)",
                arrayOf("selected_schedule_id", "selected"),
            )
        }

        val state = LightTableWidgetRepository(context, databaseFile, clock).load()
        assertTrue(state is WidgetState.OutsideTerm)
    }

    private fun createSchema(): SQLiteDatabase {
        val database = SQLiteDatabase.openOrCreateDatabase(databaseFile, null)
        database.execSQL(
            "CREATE TABLE schedules (id TEXT PRIMARY KEY, name TEXT NOT NULL, " +
                "total_weeks INTEGER NOT NULL, start_date TEXT NOT NULL, created_at INTEGER NOT NULL)",
        )
        database.execSQL(
            "CREATE TABLE courses (id TEXT PRIMARY KEY, schedule_id TEXT NOT NULL, " +
                "name TEXT NOT NULL, location TEXT NOT NULL, teacher TEXT NOT NULL, weekday INTEGER NOT NULL)",
        )
        database.execSQL(
            "CREATE TABLE periods (period_number INTEGER PRIMARY KEY, " +
                "start_minutes INTEGER NOT NULL, end_minutes INTEGER NOT NULL)",
        )
        database.execSQL(
            "CREATE TABLE course_weeks (course_id TEXT NOT NULL, week_number INTEGER NOT NULL)",
        )
        database.execSQL(
            "CREATE TABLE course_periods (course_id TEXT NOT NULL, period_number INTEGER NOT NULL)",
        )
        database.execSQL("CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)")
        return database
    }

    private fun insertSchedule(database: SQLiteDatabase, id: String, selected: Boolean) {
        database.execSQL(
            "INSERT INTO schedules VALUES (?, ?, ?, ?, ?)",
            arrayOf<Any>(id, "测试课表", 20, "2026-09-07", 1L),
        )
        if (selected) {
            database.execSQL(
                "INSERT INTO app_settings VALUES (?, ?)",
                arrayOf("selected_schedule_id", id),
            )
        }
    }

    private fun insertCourse(
        database: SQLiteDatabase,
        id: String,
        scheduleId: String,
        startMinutes: Int,
        endMinutes: Int,
        firstPeriod: Int,
        lastPeriod: Int,
    ) {
        database.execSQL(
            "INSERT INTO courses VALUES (?, ?, ?, ?, ?, ?)",
            arrayOf<Any>(id, scheduleId, "课程$id", "A101", "教师", 2),
        )
        database.execSQL("INSERT INTO course_weeks VALUES (?, ?)", arrayOf<Any>(id, 1))
        for (period in firstPeriod..lastPeriod) {
            val periodStart = if (period == firstPeriod) startMinutes else startMinutes + 50
            val periodEnd = if (period == lastPeriod) endMinutes else endMinutes - 50
            database.execSQL(
                "INSERT OR IGNORE INTO periods VALUES (?, ?, ?)",
                arrayOf(period, periodStart, periodEnd),
            )
            database.execSQL(
                "INSERT INTO course_periods VALUES (?, ?)",
                arrayOf<Any>(id, period),
            )
        }
    }
}
