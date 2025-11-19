import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/models/tool_call_request.dart';
import 'package:ai_smart_calendar/models/tool_call_response.dart';
import 'package:ai_smart_calendar/models/tool_definition.dart';
import 'package:ai_smart_calendar/repositories/task_repository.dart';
import 'package:ai_smart_calendar/providers/tasks_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarToolService {
  final TaskRepository _repository;
  final Ref _ref;

  CalendarToolService(this._repository, this._ref);

  /// 处理工具调用的统一入口
  Future<ToolCallResponse> handleCall(ToolCallRequest request) async {
    try {
      switch (request.functionName) {
        case 'create_event':
          return await _createEvent(request);
        case 'find_events':
          return await _findEvents(request);
        case 'update_event':
          return await _updateEvent(request);
        case 'delete_event':
          return await _deleteEvent(request);
        case 'get_event':
          return await _getEvent(request);
        case 'get_events':
          return await _getEvents(request);
        default:
          return ToolCallResponse.error(
            toolName: request.toolName,
            functionName: request.functionName,
            error:
                '未知的函数名: ${request.functionName}。支持的功能: create_event, find_events, update_event, delete_event, get_event, get_events',
          );
      }
    } catch (e) {
      return ToolCallResponse.error(
        toolName: request.toolName,
        functionName: request.functionName,
        error: '处理工具调用时发生异常: $e',
      );
    }
  }

  /// 创建新事件
  Future<ToolCallResponse> _createEvent(ToolCallRequest request) async {
    final Map<String, dynamic> params = request.parameters;

    // 验证必需参数
    if (params['title'] == null) {
      return ToolCallResponse.error(
        toolName: request.toolName,
        functionName: request.functionName,
        error: '缺少必需参数: title (事件标题)',
      );
    }

    if (params['dueDate'] == null) {
      return ToolCallResponse.error(
        toolName: request.toolName,
        functionName: request.functionName,
        error: '缺少必需参数: dueDate (截止日期)，请使用ISO 8601格式',
      );
    }

    // 解析日期
    DateTime? dueDate;
    try {
      dueDate = DateTime.parse(params['dueDate'] as String);
    } catch (e) {
      return ToolCallResponse.error(
        toolName: request.toolName,
        functionName: request.functionName,
        error:
            '日期格式无效: ${params['dueDate']}，请使用ISO 8601格式 (例如: 2023-12-01T10:00:00Z)',
      );
    }

    // 创建任务模型
    final TaskModel task = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: params['title'] as String,
      description: params['description'] as String? ?? '',
      createdAt: DateTime.now(),
      dueDate: dueDate,
      isCompleted: params['isCompleted'] as bool? ?? false,
      priority: _parsePriority(params['priority'] as String?),
      categoryId: params['categoryId'] as String? ?? 'default',
      tags: List<String>.from(params['tags'] as List? ?? <dynamic>[]),
      reminderTime: params['reminderTime'] != null
          ? DateTime.parse(params['reminderTime'] as String)
          : null,
      hasNotification: params['hasNotification'] as bool? ?? false,
      location: params['location'] as String?,
      recurrence: _parseRecurrence(params['recurrence'] as String?),
      aiGeneratedSuggestion: params['aiGeneratedSuggestion'] as String?,
      reminderOffsetInMinutes: params['reminderOffsetInMinutes'] as int?,
    );

    try {
      final TaskModel createdTask = await _repository.createTask(task);

      // 关键一步：在数据成功写入后，通知系统刷新！
      _ref.invalidate(tasksProvider);

      return ToolCallResponse.success(
        toolName: request.toolName,
        functionName: request.functionName,
        result: {
          'message': '事件创建成功',
          'event': createdTask.toJson(),
        },
      );
    } catch (e) {
      return ToolCallResponse.error(
        toolName: request.toolName,
        functionName: request.functionName,
        error: '创建事件失败: $e',
      );
    }
  }

  /// 查找事件
  Future<ToolCallResponse> _findEvents(ToolCallRequest request) async {
    final Map<String, dynamic> params = request.parameters;

    try {
      List<TaskModel> events;

      // 根据不同的查询条件查找事件
      if (params['date'] != null) {
        final DateTime date = DateTime.parse(params['date'] as String);
        events = await _repository.getTasksByDate(date);
      } else if (params['categoryId'] != null) {
        events = await _repository
            .getTasksByCategory(params['categoryId'] as String);
      } else if (params['completed'] == true) {
        events = await _repository.getCompletedTasks();
      } else if (params['pending'] == true) {
        events = await _repository.getPendingTasks();
      } else if (params['overdue'] == true) {
        events = await _repository.getOverdueTasks();
      } else {
        // 默认获取所有事件
        events = await _repository.getTasks();
      }

      return ToolCallResponse.success(
        toolName: request.toolName,
        functionName: request.functionName,
        result: {
          'count': events.length,
          'events': events.map((e) => e.toJson()).toList(),
        },
      );
    } catch (e) {
      return ToolCallResponse.error(
        toolName: request.toolName,
        functionName: request.functionName,
        error: '查找事件失败: $e',
      );
    }
  }

  /// 更新事件
  Future<ToolCallResponse> _updateEvent(ToolCallRequest request) async {
    final Map<String, dynamic> params = request.parameters;

    // 验证必需参数
    if (params['id'] == null) {
      return ToolCallResponse.error(
        toolName: request.toolName,
        functionName: request.functionName,
        error: '缺少必需参数: id (事件ID)',
      );
    }

    try {
      // 获取现有事件
      final TaskModel? existingTask =
          await _repository.getTaskById(params['id'] as String);
      if (existingTask == null) {
        return ToolCallResponse.error(
          toolName: request.toolName,
          functionName: request.functionName,
          error: '未找到ID为 ${params['id']} 的事件',
        );
      }

      // 更新字段
      final TaskModel updatedTask = existingTask.copyWith(
        title: params['title'] as String?,
        description: params['description'] as String?,
        dueDate: params['dueDate'] != null
            ? DateTime.parse(params['dueDate'] as String)
            : null,
        isCompleted: params['isCompleted'] as bool?,
        priority: params['priority'] != null
            ? _parsePriority(params['priority'] as String)
            : null,
        categoryId: params['categoryId'] as String?,
        tags: params['tags'] != null
            ? List<String>.from(params['tags'] as List)
            : null,
        reminderTime: params['reminderTime'] != null
            ? DateTime.parse(params['reminderTime'] as String)
            : null,
        hasNotification: params['hasNotification'] as bool?,
        location: params['location'] as String?,
        recurrence: params['recurrence'] != null
            ? _parseRecurrence(params['recurrence'] as String)
            : null,
        aiGeneratedSuggestion: params['aiGeneratedSuggestion'] as String?,
        reminderOffsetInMinutes: params['reminderOffsetInMinutes'] as int?,
      );

      final TaskModel result = await _repository.updateTask(updatedTask);

      // 关键一步：在数据成功更新后，通知系统刷新！
      _ref.invalidate(tasksProvider);

      return ToolCallResponse.success(
        toolName: request.toolName,
        functionName: request.functionName,
        result: {
          'message': '事件更新成功',
          'event': result.toJson(),
        },
      );
    } catch (e) {
      return ToolCallResponse.error(
        toolName: request.toolName,
        functionName: request.functionName,
        error: '更新事件失败: $e',
      );
    }
  }

  /// 删除事件
  Future<ToolCallResponse> _deleteEvent(ToolCallRequest request) async {
    final Map<String, dynamic> params = request.parameters;

    // 验证必需参数
    if (params['id'] == null) {
      return ToolCallResponse.error(
        toolName: request.toolName,
        functionName: request.functionName,
        error: '缺少必需参数: id (事件ID)',
      );
    }

    try {
      await _repository.deleteTask(params['id'] as String);

      // 关键一步：在数据成功删除后，通知系统刷新！
      _ref.invalidate(tasksProvider);

      return ToolCallResponse.success(
        toolName: request.toolName,
        functionName: request.functionName,
        result: {
          'message': '事件删除成功',
          'id': params['id'],
        },
      );
    } catch (e) {
      return ToolCallResponse.error(
        toolName: request.toolName,
        functionName: request.functionName,
        error: '删除事件失败: $e',
      );
    }
  }

  /// 获取单个事件
  Future<ToolCallResponse> _getEvent(ToolCallRequest request) async {
    final Map<String, dynamic> params = request.parameters;

    // 验证必需参数
    if (params['id'] == null) {
      return ToolCallResponse.error(
        toolName: request.toolName,
        functionName: request.functionName,
        error: '缺少必需参数: id (事件ID)',
      );
    }

    try {
      final TaskModel? task =
          await _repository.getTaskById(params['id'] as String);
      if (task == null) {
        return ToolCallResponse.error(
          toolName: request.toolName,
          functionName: request.functionName,
          error: '未找到ID为 ${params['id']} 的事件',
        );
      }

      return ToolCallResponse.success(
        toolName: request.toolName,
        functionName: request.functionName,
        result: {
          'event': task.toJson(),
        },
      );
    } catch (e) {
      return ToolCallResponse.error(
        toolName: request.toolName,
        functionName: request.functionName,
        error: '获取事件失败: $e',
      );
    }
  }

  /// 获取所有事件
  Future<ToolCallResponse> _getEvents(ToolCallRequest request) async {
    try {
      final List<TaskModel> events = await _repository.getTasks();
      return ToolCallResponse.success(
        toolName: request.toolName,
        functionName: request.functionName,
        result: {
          'count': events.length,
          'events': events.map((e) => e.toJson()).toList(),
        },
      );
    } catch (e) {
      return ToolCallResponse.error(
        toolName: request.toolName,
        functionName: request.functionName,
        error: '获取事件列表失败: $e',
      );
    }
  }

  /// 解析优先级
  TaskPriority _parsePriority(String? priorityStr) {
    if (priorityStr == null) return TaskPriority.medium;

    switch (priorityStr.toLowerCase()) {
      case 'low':
      case '低':
        return TaskPriority.low;
      case 'medium':
      case '中':
        return TaskPriority.medium;
      case 'high':
      case '高':
        return TaskPriority.high;
      case 'urgent':
      case '紧急':
        return TaskPriority.urgent;
      default:
        return TaskPriority.medium;
    }
  }

  /// 解析重复模式
  TaskRecurrence? _parseRecurrence(String? recurrenceStr) {
    if (recurrenceStr == null) return null;

    switch (recurrenceStr.toLowerCase()) {
      case 'none':
      case '不重复':
        return TaskRecurrence.none;
      case 'daily':
      case '每天':
        return TaskRecurrence.daily;
      case 'weekly':
      case '每周':
        return TaskRecurrence.weekly;
      case 'monthly':
      case '每月':
        return TaskRecurrence.monthly;
      case 'yearly':
      case '每年':
        return TaskRecurrence.yearly;
      default:
        return TaskRecurrence.none;
    }
  }

  /// 获取工具定义 - 用于工具注册和AI能力描述
  static ToolDefinition get toolDefinition {
    return ToolDefinitionFactory.createCalendarToolDefinition();
  }
}
