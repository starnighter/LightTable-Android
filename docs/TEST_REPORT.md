# LightTable Android 最终测试报告

测试日期：2026-09-07
应用版本：1.1.2+2
包名：`com.yangpixi.lighttable`

## 测试环境

| 环境 | 配置 |
| --- | --- |
| Flutter | 3.47.2 stable |
| Dart | 3.13.2 |
| JDK | 17 |
| Android 构建 | compileSdk 36 / targetSdk 36 / minSdk 26 |
| 最低版本模拟器 | Android 8.0 / API 26 / arm64-v8a |
| 最新版本模拟器 | Android API 36 / arm64-v8a |

`flutter doctor` 已正确识别 Flutter、Dart、JDK 17、SDK 36 和模拟器。新版 Android CLI 已移除单独的许可证确认命令，因此 Flutter 仍把许可证状态显示为 `unknown`；实际依赖解析、编译、安装和两套模拟器测试均已通过。Xcode/CocoaPods 提示不影响 Android-only 工程。

## 自动化结果

| 检查 | 结果 | 覆盖 |
| --- | --- | --- |
| `flutter analyze` | 通过，0 个问题 | 全部 Dart 源码和测试 |
| `flutter test` | 48/48 通过 | 领域、SQLite、并发初始化、批量课程读取、控制器和 Widget UI |
| `node tool/test_csu_extract_script.js` | 通过 | 同单元格多课程拆分、单双周解析和分隔线过滤 |
| `app:testDebugUnitTest` | 6/6 通过 | 小组件周次、跨日和课程优先级 |
| API 26 `connectedDebugAndroidTest` | 4/4 通过 | Kotlin 只读 SQLite 和空状态 |
| API 36 `connectedDebugAndroidTest` | 4/4 通过 | Kotlin 只读 SQLite 和空状态 |
| API 26 Flutter 集成测试 | 1/1 通过 | 真实 SQLite 完整应用流程 |
| API 36 Flutter 集成测试 | 1/1 通过 | 真实 SQLite 完整应用流程 |
| Debug APK 构建 | 通过 | `lib/main.dart` 正式应用入口 |
| Release APK 构建与启动 | 通过 | R8、WorkManager 初始化及 API 36 冷启动 |

## 交付产物

- 源码：项目根目录中的 `lib/`、`android/`、`assets/`、`test/` 和 `integration_test/`。
- Debug APK：`build/app/outputs/flutter-apk/app-debug.apk`。
- Release APK：`build/app/outputs/flutter-apk/app-release.apk`，当前使用 Debug 密钥，仅供侧载验证。
- Debug APK 大小：168,956,499 字节。
- Debug APK SHA-256：`bebe9044692c5713e3a202abc1f47d936dbf0fd88b9e3e06bc66c4e3f438b465`。
- Release APK 大小：57,211,546 字节。
- Release APK SHA-256：`62e6505d07091388531edc0e7e47f09dc3f871f36e754caa700a51059fdc6a93`。
- APK 元数据：包名 `com.yangpixi.lighttable`，版本 `1.1.2`（versionCode 2），minSdk 26，targetSdk 36。

## 设备流程回归

API 26 和 API 36 均完成以下流程：

- 冷启动并读取 SQLite 数据。
- 首页显示当前周和课程。
- 修改课程名称与地点并确认持久化。
- 修改课表名称并确认持久化。
- 打开课表管理页面。
- 新增并删除最后一个节次。
- 打开关于页和 GPLv3 许可证页。
- 卸载后的干净安装和首次数据库初始化。
- 同版本覆盖安装并验证应用私有数据保留。

桌面小组件额外验证了无数据库、无课表、学期外、当天无课、当天课程结束、正在上课、下一课程、应用普通进程终止、设备重启、跨日计算和点击打开应用。

课程表显示回归还验证了同一节次单双周课程按周切换、同周重叠课程并排显示，以及 12 节课程在 400×800 逻辑像素竖屏内无需纵向滚动。

## 启动与翻页性能回归

- `runApp` 不再等待 SQLite 初始化，Android 可以先显示 Flutter 首帧，再异步恢复课表。
- 多个启动读取共享同一个数据库打开任务，且课表、选择项和节次读取会同时发起，避免重复打开和串行等待。
- 单个课表的课程关系读取由原来的 `1 + 2 × 课程数` 次查询降为固定 3 次查询。
- 周课程过滤和冲突分栏只在数据变化时计算；左右滑动时预加载相邻周、保留已访问页面，周标题更新不会重建整个 `PageView`。
- API 36 无界面模拟器 Debug APK 三次冷启动：优化前 1801/1211/1363 ms，优化后 1459/1243/1236 ms；优化后稳定样本约 1.24 秒。Debug VM 与模拟器本身仍有固定开销，真机时间会因设备性能和课表数据量而变化。

## Android 16 Release 启动回归

- 原 Release 依赖树由 Glance 1.2.0 传递引入 WorkManager 2.7.1 和 Room 2.2.5；R8 优化后的应用在 `InitializationProvider` 阶段无法创建 `WorkDatabase`，Flutter Activity 尚未显示便已崩溃。
- 工程现在显式使用 WorkManager 2.11.2，依赖解析确认 Room 更新为 2.7.0，旧版本不再进入 Release 运行时。
- API 36 / Android 16 干净安装后首页正常显示，未出现 `AndroidRuntime` 崩溃日志。
- 修复后的 Release 连续冷启动为 659/684/465/691 ms；版本 1.1.2 最终包冷启动为 551 ms。
- 版本已更新为 1.1.2（versionCode 2），可覆盖安装在此前的 1.1.1 测试包之上；应用自身的 `lighttable.db` schema 未修改。

## 安全与仓库检查

- 应用源码主动声明联网权限；最终合并 Manifest 还包含 Glance/WorkManager 调度所需的网络状态、唤醒、开机完成和前台服务权限。
- HTTP 明文白名单仅包含中南大学教务门户主机。
- 仓库未包含签名密钥、账号、密码、访问令牌或真实个人课表。
- `build/`、`.dart_tool/`、本地截图和 IDE 文件均由 `.gitignore` 排除。
- iOS 来源工程在迁移期间保持只读、无修改。

## 仍需人工验证

学校门户依赖外部账号、验证码和实时页面，交付前建议由中南大学账号持有人在真实 Android 设备执行：

1. 完成统一身份认证登录。
2. 打开当前学期的完整课表页面。
3. 执行导入并与门户逐项核对课程、教师、地点、星期、周次和节次。
4. 关闭并重新打开应用，确认数据恢复。
5. 添加桌面小组件，确认当前课程和下一课程与应用一致。

应用不应保存登录凭据；检查完成后可在系统设置中清除 WebView 网站数据。

## 已知限制

- Android 8–11 的 Glance 动态圆角不可用，小组件可能显示直角背景。
- 系统强制停止应用后，小组件可能显示占位内容，重新打开应用可恢复。
- 启动器和系统可能延后约 30 分钟的周期刷新。
- 本项目未配置正式 Release 签名，也未执行应用商店发布验证。
