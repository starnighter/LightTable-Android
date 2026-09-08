# LightTable Android

LightTable Android 是 [yangpixi/LightTable](https://github.com/yangpixi/LightTable) 的 Flutter Android 移植版本。首版仅支持简体中文和中南大学课表导入，最低支持 Android 8.0（API 26）。

## 功能

- Material 3 首页和设置导航。
- 首帧不等待数据库打开；课表读取采用固定次数批量查询。
- 按周横向翻页的七日课表、当前日期高亮和无网格紧凑课程卡片；常规竖屏下会自适应压缩到一页。
- 支持一键回到当前周，浏览其他周后无需逐页滑回。
- 单双周同节次课程按当前周正确切换，真正同时发生的课程会并排显示。
- 相邻周提前加载，课程布局按周缓存，已查看页面在切换时保持状态。
- 支持编辑课程名称、教师、地点、连续节次和日期；临时调课只移动当前这一次课程。
- 点击课表空白节次可添加仅在当天生效的临时课程。
- 课表选择、删除、重命名、开学日期及总周数设置。
- 节次时间维护及重叠、先后顺序校验。
- 中南大学教务门户 WebView 登录和脚本提取。
- 导入内容完整校验、单事务写入和自动选中。
- 2×2 Jetpack Glance 桌面小组件，显示日期、当前周和最近课程。
- GPLv3 许可证、原作者说明和应用版本信息。

## 开发环境

已验证的基线环境：

- Flutter 3.47.2 stable
- Dart 3.13.2
- JDK 17
- Android SDK 36
- Android `compileSdk` / `targetSdk` 36
- Android `minSdk` 26

检查本机环境：

```bash
flutter doctor -v
java -version
sdkmanager --list
```

## 获取依赖与构建

在项目根目录执行：

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --target lib/main.dart
flutter build apk --release --target lib/main.dart
```

APK 输出到：

```text
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-release.apk
```

当前 Release 变体仍使用 Debug 密钥，仅用于本地侧载验证。正式发布前必须创建独立密钥、配置 Release 签名并妥善保管密钥。

## 架构

主要代码分层如下：

```text
lib/
├── app/                 应用装配、主题和依赖
├── data/                SQLite schema、数据库和 Repository 实现
├── domain/              课表模型、规则、导入解析和仓库接口
├── platform/            Flutter 与 Android 平台通道
└── presentation/        页面、控制器和课程表组件

android/app/src/main/
├── kotlin/.../widget/   Glance 小组件、日期课程计算和只读数据库访问
└── res/                 小组件配置、网络安全配置和 Android 资源
```

Flutter 负责界面、领域规则和 SQLite 写入。应用会先绘制首帧，再异步打开数据库；课表、当前选择和节次的独立读取并发启动，课程及其周次、节次关系固定使用三次批量查询。桌面小组件通过 Kotlin 只读打开同一个 `lighttable.db`；课表或节次修改成功后，Flutter 通过 Platform Channel 请求立即刷新。Glance 1.2.0 的旧版传递依赖已由工程固定到 WorkManager 2.11.2，避免 Android 16 Release 构建在 R8 优化后初始化崩溃。数据库同时保留外键、级联删除、WAL、schema 版本和迁移入口。

## 中南大学课表导入

1. 在首页选择“导入课表”。
2. 选择“中南大学”。
3. 在应用内网页完成学校统一身份认证。
4. 导航到包含完整课表的页面。
5. 点击底部导入按钮。
6. 导入成功后返回首页检查课程、周次、星期和节次。

应用不会保存账号和密码，也不会把个人课程内容写入日志。HTTP 明文访问只对白名单主机 `csujwc.its.csu.edu.cn` 开放。门户页面属于外部系统，页面结构或登录流程变化时，`assets/scripts/CsuExtractScript.js` 可能需要同步调整。

## 测试

本地静态检查、单元测试和 Widget 测试：

```bash
flutter analyze
flutter test
node tool/test_csu_extract_script.js
```

Kotlin 单元测试：

```bash
cd android
./gradlew app:testDebugUnitTest
```

连接模拟器后的 Android 数据库设备测试：

```bash
cd android
./gradlew app:connectedDebugAndroidTest
```

真实 Android 集成流程：

```bash
flutter test integration_test/app_flow_test.dart -d <device-id>
```

JavaScript 固定样本覆盖同一单元格内以分隔线排列的单双周课程，确保每门课程独立提取且分隔线不会成为课程名称。集成测试只使用脱敏固定数据，覆盖真实 SQLite 初始化、课表显示、课程编辑、课表设置、节次增删、关于页和许可证页面。最终验证结果见 [测试报告](docs/TEST_REPORT.md)。

## 桌面小组件

- 建议尺寸为 2×2，可由启动器调整大小。
- 优先显示正在进行的课程，否则显示当天接下来最多两节课程。
- 无课表、学期外、当天无课、课程结束和数据库未初始化都有独立提示。
- 数据修改后请求立即刷新，同时保留约 30 分钟的系统周期刷新。
- 点击小组件打开 LightTable 首页。

Android 8–11 不支持 Glance 的动态圆角，因此小组件背景可能呈直角。系统“强制停止”应用后，组件可能暂时显示占位内容；重新打开应用即可刷新。

## 数据与隐私

- 课表只存储在应用沙盒中的本地 SQLite 数据库。
- 不包含云同步、跨设备迁移、通知、导出或遥测。
- 不保存学校账号或密码。
- 测试固定样本不包含真实姓名、学号或课程数据。
- 应用源码主动声明联网权限；Glance/WorkManager 在合并 Manifest 中附带网络状态、唤醒、开机完成和前台服务权限，用于小组件调度，不读取通讯录、位置、相册或设备标识。

## 已知限制

- 首版只支持简体中文和中南大学。
- 学校门户需要用户在真实设备上人工登录验证。
- 手工新增仅支持从课表空白节次添加单日临时课程，不提供整学期重复课程批量创建。
- 不包含跨设备迁移、云同步、通知和课表导出。
- 不包含正式 Release 签名和应用商店发布配置。
- 桌面启动器可以延后周期刷新，30 分钟不是严格实时保证。

## 开源许可

本项目及来源项目采用 [GNU General Public License v3.0](LICENSE)。原项目版权归 yangpixi 所有，派生项目说明见 [NOTICE](NOTICE)。
