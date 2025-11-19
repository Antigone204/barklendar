// lib/services/lifecycle_manager.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/services/ai_chat_history_service.dart';
import 'package:ai_smart_calendar/services/hive_service.dart';
import 'package:ai_smart_calendar/services/notification_service.dart';
import 'package:ai_smart_calendar/utils/task_notification_scheduler.dart';

// Provider 保持不变
final startupServiceProvider = StateProvider<bool>((ref) => false);
final lifecycleManagerProvider = Provider<AppLifecycleManager>((ref) {
  final manager = AppLifecycleManager(ref);
  ref.onDispose(() => manager.dispose());
  return manager;
});

class AppLifecycleManager with WidgetsBindingObserver {
  final Ref _ref;

  // 构造函数
  AppLifecycleManager(this._ref) {
    WidgetsBinding.instance.addObserver(this);
    debugPrint('AppLifecycleManager: Instance created and observer added.');

    // 调用初始化服务
    _initializeServices();
  }

  // **【用下面的代码替换/创建你的 _initializeServices 方法】**
  Future<void> _initializeServices() async {
    debugPrint('LifecycleManager: Initializing services...');
    // 1. 首先请求权限
    final bool permissionsGranted =
        await NotificationService.requestNotificationPermission();
    debugPrint(
        'LifecycleManager: Notification permissions granted: $permissionsGranted');

    // 2. 如果获得了权限，或者在不需要权限的平台上，再执行后续任务
    if (permissionsGranted) {
      await processTaskNotificationsOnStartup();
    } else {
      debugPrint(
          'LifecycleManager: Skipping task processing due to denied permissions.');
      // 标记为已处理，防止应用恢复时再次尝试（除非用户去系统设置里开启）
      _ref.read(startupServiceProvider.notifier).state = true;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  // **核心修改**：这是一个新的公开方法，用于触发启动任务
  Future<void> processTaskNotificationsOnStartup() async {
    // 使用 Provider 作为锁，确保只执行一次
    if (_ref.read(startupServiceProvider)) {
      debugPrint(
          'LifecycleManager: Startup processing has already run, skipping.');
      return;
    }
    _ref.read(startupServiceProvider.notifier).state = true;
    debugPrint(
        'LifecycleManager: Starting initial task notification processing...');

    try {
      // 这里的逻辑保持不变
      final List<TaskModel> allTasks = HiveService.getAllTasks();
      await TaskNotificationScheduler.processAllTasksNotifications(allTasks);
      debugPrint('LifecycleManager: Initial task processing complete.');
    } catch (e) {
      debugPrint('LifecycleManager: Initial task processing failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 在应用恢复时，也调用这个方法。内部的锁会防止它重复执行。
    // 这能处理应用启动后立刻进入 resumed 状态的场景。
    if (state == AppLifecycleState.resumed) {
      processTaskNotificationsOnStartup();
    }

    // **【核心修复】**
    // 只有在应用被彻底终止时，我们才考虑关闭数据库
    // 在移动端，应用进入后台 (paused) 是正常行为，我们不应该关闭任何服务
    if (state == AppLifecycleState.detached) {
      _clearChatHistory();
      _closeHive();
    }
  }

  // 清理聊天历史
  Future<void> _clearChatHistory() async {
    try {
      // 只有在应用真正退出时才清除聊天历史
      await AIChatHistoryService.clearChatHistory();
      debugPrint('LifecycleManager: AI聊天历史已清除');
    } catch (e) {
      debugPrint('LifecycleManager: 清除聊天历史时出错: $e');
    }
  }

  // 关闭 Hive 数据库
  Future<void> _closeHive() async {
    try {
      await HiveService.close();
      debugPrint('LifecycleManager: Hive 数据库已安全关闭');
    } catch (e) {
      debugPrint('LifecycleManager: 关闭 Hive 数据库时出错: $e');
    }
  }
}
