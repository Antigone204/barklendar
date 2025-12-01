import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_smart_calendar/models/task_model.dart';

/// GoRouter 扩展方法，提供便捷的路由跳转功能
extension GoRouterExtensions on BuildContext {
  /// 跳转到任务详情页（新增或编辑）
  ///
  /// [task] 如果为 null，则跳转到新增任务页面
  /// 如果 [task] 不为 null，则跳转到编辑任务页面
  ///
  /// 返回跳转后的结果（通常是保存后的 TaskModel 或 null）
  /// 使用 pushNamed 以便可以等待返回结果
  Future<T?> toTaskDetail<T extends Object?>({
    TaskModel? task,
  }) {
    if (task == null) {
      // 新增任务：使用 add_task 路由
      return pushNamed<T>(
        'add_task',
      );
    } else {
      // 编辑任务：使用 task_detail 路由
      return pushNamed<T>(
        'task_detail',
        pathParameters: <String, String>{'taskId': task.id},
        extra: task,
      );
    }
  }
}

