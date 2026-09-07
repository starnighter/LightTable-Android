import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class WidgetRefreshService {
  static const _channel = OptionalMethodChannel(
    'com.yangpixi.lighttable/widget',
  );

  static Future<void> refresh() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('refresh');
    } on MissingPluginException {
      // Widget refresh is unavailable in unit tests and non-embedded runtimes.
    } on PlatformException {
      // Persisted app data remains valid even if a launcher rejects an update.
    } on FlutterError {
      // Some repository-only tests intentionally run without a Flutter binding.
    }
  }
}
