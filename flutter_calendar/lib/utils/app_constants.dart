// lib/utils/app_constants.dart
class AppConstants {
  // 通知设置键
  static const String notificationsEnabled = 'notifications_enabled';
  static const String taskRemindersEnabled = 'task_reminders_enabled';
  static const String dailyDigestEnabled = 'daily_digest_enabled';

  // 语言设置键
  static const String languageSetting = 'language_setting';
  static const String localeSetting = 'locale_setting';
  static const String defaultLanguage = '中文';

  // 默认值
  static const bool defaultNotificationsEnabled = true;
  static const bool defaultTaskRemindersEnabled = true;
  static const bool defaultDailyDigestEnabled = true;

  // 提醒偏移量设置
  static const String defaultReminderOffset = 'default_reminder_offset';
  static const int defaultReminderOffsetMinutes = 15; // 默认提前15分钟
}
