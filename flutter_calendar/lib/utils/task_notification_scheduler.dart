import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/services/hive_service.dart';
import 'package:ai_smart_calendar/services/notification_service.dart';
import 'package:ai_smart_calendar/utils/logger.dart';
import 'package:ai_smart_calendar/utils/app_constants.dart';

class TaskNotificationScheduler {
  // 检查通知权限并调度任务通知
  static Future<void> scheduleOrCancelTaskNotification(TaskModel task) async {
    try {
      // 检查用户设置
      final bool notificationsEnabled = HiveService.getSetting(
        AppConstants.notificationsEnabled,
        defaultValue: AppConstants.defaultNotificationsEnabled,
      ) as bool;
      final bool taskRemindersEnabled = HiveService.getSetting(
        AppConstants.taskRemindersEnabled,
        defaultValue: AppConstants.defaultTaskRemindersEnabled,
      ) as bool;

      Logger.logNotificationSettings('通知权限检查', {
        '任务ID': task.id,
        '任务标题': task.title,
        '通知总开关': notificationsEnabled,
        '任务提醒开关': taskRemindersEnabled,
        '任务完成状态': task.isCompleted,
        '任务通知开关': task.hasNotification,
        '截止日期': task.dueDate?.toString(),
        '提醒偏移量': task.reminderOffsetInMinutes,
      });

      // 如果用户关闭了任一开关，或者任务已完成，或者任务本身关闭了通知，取消通知
      if (!notificationsEnabled ||
          !taskRemindersEnabled ||
          task.isCompleted ||
          !task.hasNotification) {
        await NotificationService.cancelScheduledNotification(task.id.hashCode);
        Logger.logNotificationSettings('取消任务通知', {
          '任务ID': task.id,
          '任务标题': task.title,
          '原因': notificationsEnabled &&
                  taskRemindersEnabled &&
                  task.hasNotification
              ? '任务已完成'
              : '通知设置已关闭',
        });
        return;
      }

      // 如果任务没有截止日期，取消通知
      if (task.dueDate == null) {
        await NotificationService.cancelScheduledNotification(task.id.hashCode);
        Logger.logNotificationSettings('取消任务通知', {
          '任务ID': task.id,
          '任务标题': task.title,
          '原因': '没有截止日期',
        });
        return;
      }

      final DateTime now = DateTime.now();
      final DateTime dueDate = task.dueDate!;

      // 1. 首先，检查任务本身是否已经过期
      if (dueDate.isBefore(now)) {
        await NotificationService.cancelScheduledNotification(task.id.hashCode);
        Logger.logNotificationSettings('取消任务通知', {
          '任务ID': task.id,
          '任务标题': task.title,
          '原因': '任务已过期',
          '截止时间': dueDate.toString(),
        });
        return;
      }

      // 2. 计算最终提醒时间
      final DateTime? scheduledTime =
          _calculateScheduledTime(task, now, dueDate);

      if (scheduledTime == null) {
        await NotificationService.cancelScheduledNotification(task.id.hashCode);
        Logger.logNotificationSettings('取消任务通知', {
          '任务ID': task.id,
          '任务标题': task.title,
          '原因': '无法计算有效的提醒时间',
        });
        return;
      }

      // 3. 检查最终确定的提醒时间是否真的在未来 (这是一个安全校验)
      if (scheduledTime.isBefore(now)) {
        await NotificationService.cancelScheduledNotification(task.id.hashCode);
        Logger.logNotificationSettings('取消任务通知', {
          '任务ID': task.id,
          '任务标题': task.title,
          '原因': '最终提醒时间仍在过去',
          '提醒时间': scheduledTime.toString(),
        });
        return;
      }

      // 4. 执行最终的调度
      await NotificationService.scheduleTaskReminder(
        task: task,
        scheduledTime: scheduledTime,
      );

      Logger.logNotificationSettings('任务通知调度完成', {
        '任务ID': task.id,
        '任务标题': task.title,
        '提醒时间': scheduledTime.toString(),
        '截止时间': dueDate.toString(),
        '提醒偏移量': task.reminderOffsetInMinutes,
      });
    } catch (e) {
      Logger.logNotificationSettings('任务通知调度失败', {
        '任务ID': task.id,
        '任务标题': task.title,
        '错误': e.toString(),
      });
    }
  }

  // 计算提醒时间的核心逻辑
  static DateTime? _calculateScheduledTime(
      TaskModel task, DateTime now, DateTime dueDate) {
    // 检查是否是只选日期的任务
    if (_isDateOnly(dueDate)) {
      // 只选日期的任务：忽略偏移量，使用智能默认时间（早上9点）
      final DateTime scheduledTime =
          DateTime(dueDate.year, dueDate.month, dueDate.day, 9);
      Logger.logNotificationSettings('只选日期任务，设置默认提醒时间', {
        '任务ID': task.id,
        '任务标题': task.title,
        '默认提醒时间': scheduledTime.toString(),
      });
      return scheduledTime;
    } else {
      // 有具体时间的任务：使用用户设置的偏移量
      final int offsetMinutes = _getReminderOffsetMinutes(task);
      final DateTime scheduledTime =
          dueDate.subtract(Duration(minutes: offsetMinutes));

      Logger.logNotificationSettings('计算标准提醒时间', {
        '任务ID': task.id,
        '任务标题': task.title,
        '标准提醒时间': scheduledTime.toString(),
        '截止时间': dueDate.toString(),
        '偏移量': offsetMinutes,
      });

      // 如果标准提醒时间已经过去，但任务本身还未过期 (说明任务即将到期)
      if (scheduledTime.isBefore(now)) {
        // 安排一个"立即"通知（例如5秒后），给用户最后的提醒
        Logger.logNotificationSettings('任务即将到期，安排立即提醒', {
          '任务ID': task.id,
          '任务标题': task.title,
          '标准提醒时间': scheduledTime.toString(),
          '当前时间': now.toString(),
          '截止时间': dueDate.toString(),
        });
        return now.add(const Duration(seconds: 5));
      }

      return scheduledTime;
    }
  }

  // 获取提醒偏移量（分钟）
  static int _getReminderOffsetMinutes(TaskModel task) {
    // 决策树：任务级别设置 > 全局默认设置 > 硬编码默认值
    if (task.reminderOffsetInMinutes != null) {
      return task.reminderOffsetInMinutes!;
    }

    final int globalDefault = HiveService.getDefaultReminderOffset();
    if (globalDefault != AppConstants.defaultReminderOffsetMinutes) {
      return globalDefault;
    }

    return AppConstants.defaultReminderOffsetMinutes; // 默认15分钟
  }

  // 检查是否是只选日期的任务
  static bool _isDateOnly(DateTime date) {
    return date.hour == 0 && date.minute == 0 && date.second == 0;
  }

  // 取消任务通知
  static Future<void> cancelTaskNotification(TaskModel task) async {
    try {
      await NotificationService.cancelScheduledNotification(task.id.hashCode);
      Logger.logNotificationSettings('手动取消任务通知', {
        '任务ID': task.id,
        '任务标题': task.title,
        '操作': '成功',
      });
    } catch (e) {
      Logger.logNotificationSettings('取消任务通知失败', {
        '任务ID': task.id,
        '任务标题': task.title,
        '错误': e.toString(),
      });
    }
  }

  // 检查任务是否有待处理的通知
  static Future<bool> hasPendingNotification(TaskModel task) async {
    return await NotificationService.hasScheduledNotification(task.id.hashCode);
  }

  // 批量处理任务通知（用于应用启动时）
  static Future<void> processAllTasksNotifications(
      List<TaskModel> tasks) async {
    Logger.logNotificationSettings('批量处理任务通知', {
      '任务数量': tasks.length,
      '操作': '开始',
    });

    for (final TaskModel task in tasks) {
      await scheduleOrCancelTaskNotification(task);
    }

    Logger.logNotificationSettings('批量处理任务通知', {
      '任务数量': tasks.length,
      '操作': '完成',
    });
  }
}
