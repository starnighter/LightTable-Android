import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('zh')];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'LightTable'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get home;

  /// No description provided for @homeTitle.
  ///
  /// In zh, this message translates to:
  /// **'主页'**
  String get homeTitle;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @loadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get loadFailed;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @noScheduleTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有课表'**
  String get noScheduleTitle;

  /// No description provided for @noScheduleDescription.
  ///
  /// In zh, this message translates to:
  /// **'导入课表后，这里会按周展示每天的课程。'**
  String get noScheduleDescription;

  /// No description provided for @importSchedule.
  ///
  /// In zh, this message translates to:
  /// **'导入课表'**
  String get importSchedule;

  /// No description provided for @selectSchool.
  ///
  /// In zh, this message translates to:
  /// **'选择课表来源'**
  String get selectSchool;

  /// No description provided for @supportedSchoolHint.
  ///
  /// In zh, this message translates to:
  /// **'首版仅支持中南大学'**
  String get supportedSchoolHint;

  /// No description provided for @importNewSchedule.
  ///
  /// In zh, this message translates to:
  /// **'导入新课表'**
  String get importNewSchedule;

  /// No description provided for @portalImportHint.
  ///
  /// In zh, this message translates to:
  /// **'请登录教务系统并进入课表页面，然后点击下方导入按钮。'**
  String get portalImportHint;

  /// No description provided for @runImport.
  ///
  /// In zh, this message translates to:
  /// **'导入当前课表'**
  String get runImport;

  /// No description provided for @importing.
  ///
  /// In zh, this message translates to:
  /// **'正在验证并导入…'**
  String get importing;

  /// No description provided for @importSucceeded.
  ///
  /// In zh, this message translates to:
  /// **'课表导入成功'**
  String get importSucceeded;

  /// No description provided for @importFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败'**
  String get importFailed;

  /// No description provided for @importPageRequired.
  ///
  /// In zh, this message translates to:
  /// **'请确认已经进入课表页面后重试。'**
  String get importPageRequired;

  /// No description provided for @webPageLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'页面加载失败'**
  String get webPageLoadFailed;

  /// No description provided for @webBack.
  ///
  /// In zh, this message translates to:
  /// **'网页后退'**
  String get webBack;

  /// No description provided for @webForward.
  ///
  /// In zh, this message translates to:
  /// **'网页前进'**
  String get webForward;

  /// No description provided for @webRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新网页'**
  String get webRefresh;

  /// No description provided for @privacyHint.
  ///
  /// In zh, this message translates to:
  /// **'账号和密码仅由学校网页处理，LightTable 不会保存。'**
  String get privacyHint;

  /// No description provided for @scheduleSettings.
  ///
  /// In zh, this message translates to:
  /// **'课表设置'**
  String get scheduleSettings;

  /// No description provided for @scheduleManagement.
  ///
  /// In zh, this message translates to:
  /// **'课表管理'**
  String get scheduleManagement;

  /// No description provided for @periodSettings.
  ///
  /// In zh, this message translates to:
  /// **'节次时间'**
  String get periodSettings;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @weekTitle.
  ///
  /// In zh, this message translates to:
  /// **'第 {week} 周'**
  String weekTitle(int week);

  /// No description provided for @notCurrentWeek.
  ///
  /// In zh, this message translates to:
  /// **'非本周'**
  String get notCurrentWeek;

  /// No description provided for @returnToCurrentWeek.
  ///
  /// In zh, this message translates to:
  /// **'回到当前周'**
  String get returnToCurrentWeek;

  /// No description provided for @monthTitle.
  ///
  /// In zh, this message translates to:
  /// **'{month}月'**
  String monthTitle(int month);

  /// No description provided for @weekdaySunday.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get weekdaySunday;

  /// No description provided for @weekdayMonday.
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In zh, this message translates to:
  /// **'五'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In zh, this message translates to:
  /// **'六'**
  String get weekdaySaturday;

  /// No description provided for @courseName.
  ///
  /// In zh, this message translates to:
  /// **'课程名称'**
  String get courseName;

  /// No description provided for @addCourse.
  ///
  /// In zh, this message translates to:
  /// **'添加课程'**
  String get addCourse;

  /// No description provided for @editCourse.
  ///
  /// In zh, this message translates to:
  /// **'编辑课程'**
  String get editCourse;

  /// No description provided for @courseDate.
  ///
  /// In zh, this message translates to:
  /// **'上课日期'**
  String get courseDate;

  /// No description provided for @courseDateValue.
  ///
  /// In zh, this message translates to:
  /// **'{year}年{month}月{day}日 · 第 {week} 周'**
  String courseDateValue(int year, int month, int day, int week);

  /// No description provided for @teacher.
  ///
  /// In zh, this message translates to:
  /// **'教师'**
  String get teacher;

  /// No description provided for @location.
  ///
  /// In zh, this message translates to:
  /// **'上课地点'**
  String get location;

  /// No description provided for @classTime.
  ///
  /// In zh, this message translates to:
  /// **'上课时间'**
  String get classTime;

  /// No description provided for @coursePeriodRange.
  ///
  /// In zh, this message translates to:
  /// **'第 {start}–{end} 节'**
  String coursePeriodRange(int start, int end);

  /// No description provided for @requiredField.
  ///
  /// In zh, this message translates to:
  /// **'此项不能为空'**
  String get requiredField;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get saved;

  /// No description provided for @currentSchedule.
  ///
  /// In zh, this message translates to:
  /// **'当前课表'**
  String get currentSchedule;

  /// No description provided for @selectSchedule.
  ///
  /// In zh, this message translates to:
  /// **'请选择课表'**
  String get selectSchedule;

  /// No description provided for @scheduleName.
  ///
  /// In zh, this message translates to:
  /// **'课表名称'**
  String get scheduleName;

  /// No description provided for @totalWeeks.
  ///
  /// In zh, this message translates to:
  /// **'学期周数'**
  String get totalWeeks;

  /// No description provided for @totalWeeksValue.
  ///
  /// In zh, this message translates to:
  /// **'{weeks} 周'**
  String totalWeeksValue(int weeks);

  /// No description provided for @startDate.
  ///
  /// In zh, this message translates to:
  /// **'开学日期'**
  String get startDate;

  /// No description provided for @noScheduleForSettings.
  ///
  /// In zh, this message translates to:
  /// **'请先导入并选择一个课表'**
  String get noScheduleForSettings;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @deleteScheduleTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除课表？'**
  String get deleteScheduleTitle;

  /// No description provided for @deleteScheduleMessage.
  ///
  /// In zh, this message translates to:
  /// **'“{name}”及其课程将被永久删除。'**
  String deleteScheduleMessage(String name);

  /// No description provided for @deleteScheduleDone.
  ///
  /// In zh, this message translates to:
  /// **'课表已删除'**
  String get deleteScheduleDone;

  /// No description provided for @selected.
  ///
  /// In zh, this message translates to:
  /// **'当前使用'**
  String get selected;

  /// No description provided for @noSchedules.
  ///
  /// In zh, this message translates to:
  /// **'暂无课表'**
  String get noSchedules;

  /// No description provided for @periodNumber.
  ///
  /// In zh, this message translates to:
  /// **'第 {number} 节'**
  String periodNumber(int number);

  /// No description provided for @startTime.
  ///
  /// In zh, this message translates to:
  /// **'开始时间'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In zh, this message translates to:
  /// **'结束时间'**
  String get endTime;

  /// No description provided for @addPeriod.
  ///
  /// In zh, this message translates to:
  /// **'新增节次'**
  String get addPeriod;

  /// No description provided for @deleteLastPeriod.
  ///
  /// In zh, this message translates to:
  /// **'删除最后一节'**
  String get deleteLastPeriod;

  /// No description provided for @periodHint.
  ///
  /// In zh, this message translates to:
  /// **'相邻节次不得重叠；只能从末尾新增或删除。'**
  String get periodHint;

  /// No description provided for @version.
  ///
  /// In zh, this message translates to:
  /// **'版本 {version}'**
  String version(String version);

  /// No description provided for @license.
  ///
  /// In zh, this message translates to:
  /// **'开源许可证'**
  String get license;

  /// No description provided for @licenseName.
  ///
  /// In zh, this message translates to:
  /// **'GNU General Public License v3.0'**
  String get licenseName;

  /// No description provided for @originalAuthor.
  ///
  /// In zh, this message translates to:
  /// **'原作者'**
  String get originalAuthor;

  /// No description provided for @originalAuthorValue.
  ///
  /// In zh, this message translates to:
  /// **'yangpixi / LightTable'**
  String get originalAuthorValue;

  /// No description provided for @derivedProject.
  ///
  /// In zh, this message translates to:
  /// **'这是 LightTable 的 Flutter Android 移植版本。'**
  String get derivedProject;

  /// No description provided for @copyrightText.
  ///
  /// In zh, this message translates to:
  /// **'Copyright © 2026 yangpixi'**
  String get copyrightText;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
