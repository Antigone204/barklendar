import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // **【用下面的代码替换你现有的 initialize 方法】**
  static Future<void> initialize() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        _notificationsPlugin;

// 初始化时区数据库
    tz.initializeTimeZones();

    // 1. 使用 var 让 Dart 自己推断类型（不管它是 String 还是 TimezoneInfo）
    final TimezoneInfo timeZoneResult = await FlutterTimezone.getLocalTimezone();

    // 2. 无论它返回什么，都强转成 String (通过 .toString())
    // 这样能兼容 String 和可能出现的对象类型
    final String timeZoneName = timeZoneResult.toString();

    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // 兜底：如果有些奇怪的时区名字（比如 'Asia/Shanghai' 写成了其他格式）导致解析失败
      // 我们默认回退到 UTC，防止应用崩溃
      debugPrint("【警告】无法解析本地时区 '$timeZoneName'，回退到 UTC。错误: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 为 Android 设置初始化参数
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // **【核心修复】** 为 iOS 和 macOS 设置初始化参数，并明确开启前台通知权限
    final DarwinInitializationSettings initializationSettingsDarwin =
        const DarwinInitializationSettings(
      
    );

    // 组合各平台的初始化设置
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    // 执行初始化
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        // 用户点击通知后的回调
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          debugPrint('Notification payload: $payload');
        }
        // 处理通知点击
        _handleNotificationClick(payload);
      },
    );

    // 创建 Android 通知渠道
    await _createAndroidNotificationChannels();

    debugPrint(
        'Notification Service Initialized with foreground presentation options.',);
  }

  // 创建 Android 通知渠道
  static Future<void> _createAndroidNotificationChannels() async {
    // 任务提醒渠道
    const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
      'task_reminders',
      '任务提醒',
      description: '任务到期和提醒通知',
      importance: Importance.high,
    );

    // 创建渠道
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(taskChannel);
  }

  // 显示即时通知
  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'task_reminders',
      '任务提醒',
      channelDescription: '任务到期和提醒通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
      macOS: darwinPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // 取消特定通知
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // 取消所有通知
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // 获取待处理通知
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  // 处理通知点击
  static void _handleNotificationClick(String? payload) {
    if (payload == null) return;

    try {
      final Map<String, dynamic> data =
          jsonDecode(payload) as Map<String, dynamic>;
      final String type = data['type'] as String;

      switch (type) {
        case 'task_reminder':
          final String taskId = data['task_id'] as String;
          // TODO: 跳转到任务详情页面
          debugPrint('跳转到任务详情: $taskId');
          break;
        case 'daily_digest':
          // TODO: 跳转到今日任务页面
          debugPrint('跳转到今日任务');
          break;
        case 'ai_suggestion':
          // TODO: 跳转到 AI 建议页面
          debugPrint('跳转到 AI 建议');
          break;
      }
    } catch (e) {
      debugPrint('解析通知 payload 失败: $e');
    }
  }

  // 显示任务到期通知
  static Future<void> showTaskDueNotification(TaskModel task) async {
    await showInstantNotification(
      title: '📅 任务即将到期: ${task.title}',
      body: task.description.isNotEmpty ? task.description : '请及时处理该任务',
      payload: jsonEncode(<String, String>{
        'type': 'task_reminder',
        'task_id': task.id,
      }),
      id: task.id.hashCode,
    );
  }

  // 显示任务完成通知
  static Future<void> showTaskCompletedNotification(TaskModel task) async {
    await showInstantNotification(
      title: '✅ 任务完成: ${task.title}',
      body: '恭喜您完成了一个任务！',
      payload: jsonEncode(<String, String>{
        'type': 'task_completed',
        'task_id': task.id,
      }),
      id: task.id.hashCode + 1000, // 避免与到期通知 ID 冲突
    );
  }

  // 显示每日摘要通知
  static Future<void> showDailyDigest({
    required int totalTasks,
    required int completedTasks,
    required int overdueTasks,
  }) async {
    final String title = '📊 今日任务摘要';
    final String body = '''
总任务: $totalTasks 个
已完成: $completedTasks 个
已过期: $overdueTasks 个
    ''';

    await showInstantNotification(
      title: title,
      body: body,
      payload: jsonEncode(<String, String>{
        'type': 'daily_digest',
        'date': DateTime.now().toIso8601String(),
      }),
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  // 显示 AI 建议通知
  static Future<void> showAISuggestionNotification(String suggestion) async {
    await showInstantNotification(
      title: '🤖 AI 智能建议',
      body: suggestion,
      payload: jsonEncode(<String, String>{
        'type': 'ai_suggestion',
        'suggestion': suggestion,
      }),
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  // 检查通知权限
  static Future<bool> checkNotificationPermission() async {
    final bool? result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();

    return result ?? false;
  }

  // 请求通知权限
  static Future<bool> requestNotificationPermission() async {
    // 确保 Flutter 服务已绑定
    WidgetsFlutterBinding.ensureInitialized();

    // 获取插件实例
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    bool? result = false;

    if (Platform.isIOS) {
      debugPrint('Requesting iOS notification permissions...');
      result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      debugPrint('iOS permission request result: $result');
    } else if (Platform.isMacOS) {
      debugPrint('Requesting macOS notification permissions...');
      result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      debugPrint('macOS permission request result: $result');
    } else if (Platform.isAndroid) {
      debugPrint('Requesting Android notification permissions...');
      // 对于 Android 13 (API 33) 及以上版本
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      result = await androidImplementation?.requestNotificationsPermission();
      debugPrint('Android permission request result: $result');
    } else {
      // 其他平台默认认为有权限
      debugPrint(
          'Platform is not iOS, macOS, or Android. Assuming permission is granted.',);
      return true;
    }

    return result ?? false;
  }

  // 清除所有通知徽章
  static Future<void> clearBadge() async {
    // 徽章清除主要针对 iOS/macOS，Android 不需要此功能
    debugPrint('清除通知徽章');
  }

  // --- 定时调度功能 ---

  // 安排任务提醒通知
  static Future<void> scheduleTaskReminder({
    required TaskModel task,
    required DateTime scheduledTime,
  }) async {
    try {
      // 检查是否已经过期
      if (scheduledTime.isBefore(DateTime.now())) {
        Logger.logNotificationSettings('定时通知调度失败', <String, dynamic>{
          '任务ID': task.id,
          '任务标题': task.title,
          '原因': '计划时间已过期',
          '计划时间': scheduledTime.toString(),
        });
        return;
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'task_reminders',
        '任务提醒',
        channelDescription: '任务到期和提醒通知',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails darwinPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: darwinPlatformChannelSpecifics,
        macOS: darwinPlatformChannelSpecifics,
      );

      // 使用 zonedSchedule 方法安排定时通知
      await _notificationsPlugin.zonedSchedule(
        task.id.hashCode, // 使用任务ID作为通知ID
        '📅 任务即将到期: ${task.title}',
        task.description.isNotEmpty ? task.description : '请及时处理该任务',
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformChannelSpecifics,
        payload: jsonEncode(<String, String>{
          'type': 'task_reminder',
          'task_id': task.id,
        }),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      Logger.logNotificationSettings('定时通知调度成功', <String, dynamic>{
        '任务ID': task.id,
        '任务标题': task.title,
        '计划时间': scheduledTime.toString(),
        '通知ID': task.id.hashCode,
      });
    } catch (e) {
      Logger.logNotificationSettings('定时通知调度失败', <String, dynamic>{
        '任务ID': task.id,
        '任务标题': task.title,
        '错误': e.toString(),
      });
    }
  }

  // 取消特定任务的定时通知
  static Future<void> cancelScheduledNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      Logger.logNotificationSettings('取消定时通知', <String, dynamic>{
        '通知ID': id,
        '操作': '成功',
      });
    } catch (e) {
      Logger.logNotificationSettings('取消定时通知失败', <String, dynamic>{
        '通知ID': id,
        '错误': e.toString(),
      });
    }
  }

  // 检查是否有待处理的定时通知
  static Future<bool> hasScheduledNotification(int id) async {
    final List<PendingNotificationRequest> pendingNotifications =
        await _notificationsPlugin.pendingNotificationRequests();
    return pendingNotifications.any((PendingNotificationRequest notification) => notification.id == id);
  }
}
