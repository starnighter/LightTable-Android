package com.yangpixi.lighttable.widget

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.color.ColorProvider
import androidx.glance.action.clickable
import com.yangpixi.lighttable.MainActivity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.LocalDate

internal class LightTableWidget : GlanceAppWidget() {
    override val sizeMode: SizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val state = withContext(Dispatchers.IO) {
            LightTableWidgetRepository(context).load()
        }
        provideContent {
            LightTableWidgetContent(state)
        }
    }
}

internal class LightTableWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = LightTableWidget()
}

@Composable
internal fun LightTableWidgetContent(state: WidgetState) {
    val context = LocalContext.current
    val date = state.dateOrToday()
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(WidgetColors.background)
            .cornerRadius(20.dp)
            .clickable(actionStartActivity(Intent(context, MainActivity::class.java)))
            .padding(12.dp),
    ) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.Vertical.CenterVertically,
        ) {
            Image(
                provider = ImageProvider(com.yangpixi.lighttable.R.mipmap.ic_launcher),
                contentDescription = "LightTable",
                modifier = GlanceModifier.size(22.dp).cornerRadius(6.dp),
            )
            Spacer(GlanceModifier.width(7.dp))
            Text(
                text = formatDate(date),
                style = TextStyle(
                    color = WidgetColors.text,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 1,
            )
            Spacer(GlanceModifier.defaultWeight())
            state.weekOrNull()?.let { week ->
                Text(
                    text = "第${week}周",
                    style = TextStyle(
                        color = WidgetColors.secondaryText,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                    ),
                    maxLines = 1,
                )
            }
        }
        Spacer(GlanceModifier.height(9.dp))

        when (state) {
            WidgetState.DatabaseUnavailable -> EmptyState(
                title = "请先打开 LightTable",
                detail = "初始化课表后小组件会自动刷新",
            )
            is WidgetState.NoSchedule -> EmptyState(
                title = "暂无课表",
                detail = "打开应用导入课表",
            )
            is WidgetState.OutsideTerm -> EmptyState(
                title = "当前不在学期内",
                detail = "可在应用中检查开学日期",
            )
            is WidgetState.NoCourses -> EmptyState(
                title = "今天没有课程",
                detail = "享受空闲的一天",
            )
            is WidgetState.FinishedForToday -> EmptyState(
                title = "今天的课程已结束",
                detail = "点击查看本周课表",
            )
            is WidgetState.Courses -> CourseState(state)
        }
    }
}

@Composable
private fun CourseState(state: WidgetState.Courses) {
    CourseCard(
        label = if (state.primaryIsOngoing) "正在进行" else "下一课程",
        course = state.primary,
        emphasized = true,
    )
    state.secondary?.let { course ->
        Spacer(GlanceModifier.height(7.dp))
        CourseCard(label = "随后", course = course, emphasized = false)
    }
}

@Composable
private fun CourseCard(
    label: String,
    course: WidgetCourse,
    emphasized: Boolean,
) {
    val background = if (emphasized) WidgetColors.course else WidgetColors.secondaryCourse
    val textColor = if (emphasized) WidgetColors.onCourse else WidgetColors.text
    val secondaryColor = if (emphasized) WidgetColors.onCourseMuted else WidgetColors.secondaryText
    Column(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(background)
            .cornerRadius(12.dp)
            .padding(horizontal = 9.dp, vertical = 7.dp),
    ) {
        Row(modifier = GlanceModifier.fillMaxWidth()) {
            Text(
                text = label,
                style = TextStyle(
                    color = secondaryColor,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Medium,
                ),
                maxLines = 1,
            )
            Spacer(GlanceModifier.defaultWeight())
            Text(
                text = course.periodLabel,
                style = TextStyle(color = secondaryColor, fontSize = 10.sp),
                maxLines = 1,
            )
        }
        Text(
            text = course.name,
            style = TextStyle(
                color = textColor,
                fontSize = if (emphasized) 15.sp else 13.sp,
                fontWeight = FontWeight.Bold,
            ),
            maxLines = 1,
        )
        val detail = listOf(course.timeLabel, course.location)
            .filter { it.isNotBlank() }
            .joinToString(" · ")
        Text(
            text = detail,
            style = TextStyle(color = secondaryColor, fontSize = 10.sp),
            maxLines = 1,
        )
    }
}

@Composable
private fun EmptyState(title: String, detail: String) {
    Column(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(WidgetColors.emptySurface)
            .cornerRadius(12.dp)
            .padding(12.dp),
    ) {
        Text(
            text = title,
            style = TextStyle(
                color = WidgetColors.text,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
            ),
            maxLines = 1,
        )
        Spacer(GlanceModifier.height(3.dp))
        Text(
            text = detail,
            style = TextStyle(color = WidgetColors.secondaryText, fontSize = 11.sp),
            maxLines = 2,
        )
    }
}

private fun WidgetState.dateOrToday(): LocalDate = when (this) {
    WidgetState.DatabaseUnavailable -> LocalDate.now()
    is WidgetState.NoSchedule -> date
    is WidgetState.OutsideTerm -> date
    is WidgetState.NoCourses -> date
    is WidgetState.FinishedForToday -> date
    is WidgetState.Courses -> date
}

private fun WidgetState.weekOrNull(): Int? = when (this) {
    is WidgetState.NoCourses -> week
    is WidgetState.FinishedForToday -> week
    is WidgetState.Courses -> week
    else -> null
}

private fun formatDate(date: LocalDate): String {
    val weekday = listOf("一", "二", "三", "四", "五", "六", "日")[date.dayOfWeek.value - 1]
    return "${date.monthValue}月${date.dayOfMonth}日 周$weekday"
}

private object WidgetColors {
    val background = ColorProvider(Color(0xFFF6FAFE), Color(0xFF101820))
    val emptySurface = ColorProvider(Color(0xFFE6EFF7), Color(0xFF243541))
    val course = ColorProvider(Color(0xFF2F80ED), Color(0xFF175C9E))
    val secondaryCourse = ColorProvider(Color(0xFFD7E9FF), Color(0xFF174A73))
    val text = ColorProvider(Color(0xFF13232B), Color(0xFFF2F6F8))
    val secondaryText = ColorProvider(Color(0xFF546A75), Color(0xFFBDCBD2))
    val onCourse = ColorProvider(Color.White, Color.White)
    val onCourseMuted = ColorProvider(Color(0xFFE6F1FF), Color(0xFFD7E9FF))
}
