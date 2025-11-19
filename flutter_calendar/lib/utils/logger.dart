import 'package:flutter/foundation.dart';

// 日志工具类，用于调试和监控通知设置的持久化
class Logger {
  static const bool _debugMode = true;

  static void logNotificationSettings(
      String action, Map<String, dynamic> data) {
    if (!_debugMode) return;

    final timestamp = DateTime.now();
    debugPrint('[通知设置] $action - $timestamp');
    data.forEach((key, value) {
      debugPrint('  - $key: $value');
    });
    debugPrint('---');
  }

  static void logSettingChange(
      String settingKey, dynamic oldValue, dynamic newValue) {
    if (!_debugMode) return;

    final timestamp = DateTime.now();
    debugPrint('[设置变更] $timestamp');
    debugPrint('  - 设置项: $settingKey');
    debugPrint('  - 旧值: $oldValue');
    debugPrint('  - 新值: $newValue');
    debugPrint('---');
  }

  static void logPersistenceOperation(
      String operation, String key, dynamic value) {
    if (!_debugMode) return;

    final timestamp = DateTime.now();
    debugPrint('[持久化操作] $operation - $timestamp');
    debugPrint('  - 键: $key');
    debugPrint('  - 值: $value');
    debugPrint('---');
  }
}
