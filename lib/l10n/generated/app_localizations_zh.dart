// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'LightTable';

  @override
  String get home => '首页';

  @override
  String get homeTitle => '主页';

  @override
  String get settings => '设置';

  @override
  String get loadFailed => '加载失败';

  @override
  String get retry => '重试';

  @override
  String get noScheduleTitle => '还没有课表';

  @override
  String get noScheduleDescription => '导入课表后，这里会按周展示每天的课程。';

  @override
  String get importSchedule => '导入课表';

  @override
  String get selectSchool => '选择课表来源';

  @override
  String get supportedSchoolHint => '首版仅支持中南大学';

  @override
  String get importNewSchedule => '导入新课表';

  @override
  String get portalImportHint => '请登录教务系统并进入课表页面，然后点击下方导入按钮。';

  @override
  String get runImport => '导入当前课表';

  @override
  String get importing => '正在验证并导入…';

  @override
  String get importSucceeded => '课表导入成功';

  @override
  String get importFailed => '导入失败';

  @override
  String get importPageRequired => '请确认已经进入课表页面后重试。';

  @override
  String get webPageLoadFailed => '页面加载失败';

  @override
  String get webBack => '网页后退';

  @override
  String get webForward => '网页前进';

  @override
  String get webRefresh => '刷新网页';

  @override
  String get privacyHint => '账号和密码仅由学校网页处理，LightTable 不会保存。';

  @override
  String get scheduleSettings => '课表设置';

  @override
  String get scheduleManagement => '课表管理';

  @override
  String get periodSettings => '节次时间';

  @override
  String get about => '关于';

  @override
  String weekTitle(int week) {
    return '第 $week 周';
  }

  @override
  String get notCurrentWeek => '非本周';

  @override
  String monthTitle(int month) {
    return '$month月';
  }

  @override
  String get weekdaySunday => '日';

  @override
  String get weekdayMonday => '一';

  @override
  String get weekdayTuesday => '二';

  @override
  String get weekdayWednesday => '三';

  @override
  String get weekdayThursday => '四';

  @override
  String get weekdayFriday => '五';

  @override
  String get weekdaySaturday => '六';

  @override
  String get courseName => '课程名称';

  @override
  String get teacher => '教师';

  @override
  String get location => '上课地点';

  @override
  String get classTime => '上课时间';

  @override
  String coursePeriodRange(int start, int end) {
    return '第 $start–$end 节';
  }

  @override
  String get requiredField => '此项不能为空';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get saved => '已保存';

  @override
  String get currentSchedule => '当前课表';

  @override
  String get selectSchedule => '请选择课表';

  @override
  String get scheduleName => '课表名称';

  @override
  String get totalWeeks => '学期周数';

  @override
  String totalWeeksValue(int weeks) {
    return '$weeks 周';
  }

  @override
  String get startDate => '开学日期';

  @override
  String get noScheduleForSettings => '请先导入并选择一个课表';

  @override
  String get delete => '删除';

  @override
  String get deleteScheduleTitle => '删除课表？';

  @override
  String deleteScheduleMessage(String name) {
    return '“$name”及其课程将被永久删除。';
  }

  @override
  String get deleteScheduleDone => '课表已删除';

  @override
  String get selected => '当前使用';

  @override
  String get noSchedules => '暂无课表';

  @override
  String periodNumber(int number) {
    return '第 $number 节';
  }

  @override
  String get startTime => '开始时间';

  @override
  String get endTime => '结束时间';

  @override
  String get addPeriod => '新增节次';

  @override
  String get deleteLastPeriod => '删除最后一节';

  @override
  String get periodHint => '相邻节次不得重叠；只能从末尾新增或删除。';

  @override
  String version(String version) {
    return '版本 $version';
  }

  @override
  String get license => '开源许可证';

  @override
  String get licenseName => 'GNU General Public License v3.0';

  @override
  String get originalAuthor => '原作者';

  @override
  String get originalAuthorValue => 'yangpixi / LightTable';

  @override
  String get derivedProject => '这是 LightTable 的 Flutter Android 移植版本。';

  @override
  String get copyrightText => 'Copyright © 2026 yangpixi';

  @override
  String get done => '完成';
}
