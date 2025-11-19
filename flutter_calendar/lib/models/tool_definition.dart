import 'package:ai_smart_calendar/models/task_model.dart';

class ToolDefinition {
  final String name; // 工具名称，如 "calendar"
  final String description; // 给AI看的清晰描述
  final List<FunctionDefinition> functions;

  ToolDefinition({
    required this.name,
    required this.description,
    required this.functions,
  });

  // 转换为JSON Schema格式（用于OpenAI等模型）
  Map<String, dynamic> toJsonSchema() {
    return {
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'description': description},
        'functions': {
          'type': 'array',
          'items': functions.map((f) => f.toJsonSchema()).toList(),
        },
      },
    };
  }
}

class FunctionDefinition {
  final String name; // 函数名，如 "create_event"
  final String description; // 函数功能的详细描述
  final Map<String, dynamic> parameters; // JSON Schema参数定义

  FunctionDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJsonSchema() {
    return {
      'name': name,
      'description': description,
      'parameters': parameters,
    };
  }
}

// 工具定义工厂类，用于创建标准的工具定义
class ToolDefinitionFactory {
  /// 创建日历工具的定义
  static ToolDefinition createCalendarToolDefinition() {
    return ToolDefinition(
      name: 'calendar',
      description: '帮助用户管理日历事件、任务和日程安排。可以创建、查找、更新、删除事件，并支持优先级、重复模式、提醒等功能。',
      functions: [
        FunctionDefinition(
          name: 'create_event',
          description: '在用户日历中创建新事件或任务',
          parameters: const <String, dynamic>{
            'type': 'object',
            'properties': const <String, dynamic>{
              'title': {'type': 'string', 'description': '事件标题（必需）'},
              'description': {'type': 'string', 'description': '事件详细描述'},
              'dueDate': {
                'type': 'string',
                'description': '截止日期，ISO 8601格式（必需）'
              },
              'priority': {
                'type': 'string',
                'enum': ['low', 'medium', 'high', 'urgent'],
                'description': '优先级'
              },
              'categoryId': {'type': 'string', 'description': '分类ID'},
              'tags': {
                'type': 'array',
                'items': {'type': 'string'},
                'description': '标签列表'
              },
              'reminderTime': {
                'type': 'string',
                'description': '提醒时间，ISO 8601格式'
              },
              'hasNotification': {'type': 'boolean', 'description': '是否启用通知'},
              'location': {'type': 'string', 'description': '事件地点'},
              'recurrence': {
                'type': 'string',
                'enum': ['none', 'daily', 'weekly', 'monthly', 'yearly'],
                'description': '重复模式'
              },
            },
            'required': ['title', 'dueDate'],
          },
        ),
        FunctionDefinition(
          name: 'find_events',
          description: '根据日期、分类、状态等条件查找事件',
          parameters: const <String, dynamic>{
            'type': 'object',
            'properties': const <String, dynamic>{
              'date': {'type': 'string', 'description': '查询特定日期的事件，ISO 8601格式'},
              'categoryId': {'type': 'string', 'description': '按分类筛选'},
              'completed': {'type': 'boolean', 'description': '是否已完成'},
              'pending': {'type': 'boolean', 'description': '是否待完成'},
              'overdue': {'type': 'boolean', 'description': '是否过期'},
            },
          },
        ),
        FunctionDefinition(
          name: 'update_event',
          description: '更新现有事件的详细信息',
          parameters: const <String, dynamic>{
            'type': 'object',
            'properties': const <String, dynamic>{
              'id': {'type': 'string', 'description': '事件ID（必需）'},
              'title': {'type': 'string', 'description': '事件标题'},
              'description': {'type': 'string', 'description': '事件详细描述'},
              'dueDate': {'type': 'string', 'description': '截止日期，ISO 8601格式'},
              'priority': {
                'type': 'string',
                'enum': ['low', 'medium', 'high', 'urgent'],
                'description': '优先级'
              },
              'categoryId': {'type': 'string', 'description': '分类ID'},
              'isCompleted': {'type': 'boolean', 'description': '是否已完成'},
            },
            'required': ['id'],
          },
        ),
        FunctionDefinition(
          name: 'delete_event',
          description: '删除指定的事件',
          parameters: const <String, dynamic>{
            'type': 'object',
            'properties': const <String, dynamic>{
              'id': {'type': 'string', 'description': '要删除的事件ID（必需）'},
            },
            'required': ['id'],
          },
        ),
        FunctionDefinition(
          name: 'get_event',
          description: '获取单个事件的详细信息',
          parameters: const <String, dynamic>{
            'type': 'object',
            'properties': const <String, dynamic>{
              'id': {'type': 'string', 'description': '事件ID（必需）'},
            },
            'required': ['id'],
          },
        ),
        FunctionDefinition(
          name: 'get_events',
          description: '获取所有事件的列表',
          parameters: const <String, dynamic>{
            'type': 'object',
            'properties': const <String, dynamic>{
              // 无参数，获取所有事件
            },
          },
        ),
      ],
    );
  }
}
