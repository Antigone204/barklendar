
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
    return <String, dynamic>{
      'type': 'object',
      'properties': <String, Map<String, Object>>{
        'name': <String, String>{'type': 'string', 'description': description},
        'functions': <String, Object>{
          'type': 'array',
          'items': functions.map((FunctionDefinition f) => f.toJsonSchema()).toList(),
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
    return <String, dynamic>{
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
      functions: <FunctionDefinition>[
        FunctionDefinition(
          name: 'create_event',
          description: '在用户日历中创建新事件或任务',
          parameters: const <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{
              'title': <String, String>{'type': 'string', 'description': '事件标题（必需）'},
              'description': <String, String>{'type': 'string', 'description': '事件详细描述'},
              'dueDate': <String, String>{
                'type': 'string',
                'description': '截止日期，ISO 8601格式（必需）',
              },
              'priority': <String, Object>{
                'type': 'string',
                'enum': <String>['low', 'medium', 'high', 'urgent'],
                'description': '优先级',
              },
              'categoryId': <String, String>{'type': 'string', 'description': '分类ID'},
              'tags': <String, Object>{
                'type': 'array',
                'items': <String, String>{'type': 'string'},
                'description': '标签列表',
              },
              'reminderTime': <String, String>{
                'type': 'string',
                'description': '提醒时间，ISO 8601格式',
              },
              'hasNotification': <String, String>{'type': 'boolean', 'description': '是否启用通知'},
              'location': <String, String>{'type': 'string', 'description': '事件地点'},
              'recurrence': <String, Object>{
                'type': 'string',
                'enum': <String>['none', 'daily', 'weekly', 'monthly', 'yearly'],
                'description': '重复模式',
              },
            },
            'required': <String>['title', 'dueDate'],
          },
        ),
        FunctionDefinition(
          name: 'find_events',
          description: '根据日期、分类、状态等条件查找事件',
          parameters: const <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{
              'date': <String, String>{'type': 'string', 'description': '查询特定日期的事件，ISO 8601格式'},
              'categoryId': <String, String>{'type': 'string', 'description': '按分类筛选'},
              'completed': <String, String>{'type': 'boolean', 'description': '是否已完成'},
              'pending': <String, String>{'type': 'boolean', 'description': '是否待完成'},
              'overdue': <String, String>{'type': 'boolean', 'description': '是否过期'},
            },
          },
        ),
        FunctionDefinition(
          name: 'update_event',
          description: '更新现有事件的详细信息',
          parameters: const <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{
              'id': <String, String>{'type': 'string', 'description': '事件ID（必需）'},
              'title': <String, String>{'type': 'string', 'description': '事件标题'},
              'description': <String, String>{'type': 'string', 'description': '事件详细描述'},
              'dueDate': <String, String>{'type': 'string', 'description': '截止日期，ISO 8601格式'},
              'priority': <String, Object>{
                'type': 'string',
                'enum': <String>['low', 'medium', 'high', 'urgent'],
                'description': '优先级',
              },
              'categoryId': <String, String>{'type': 'string', 'description': '分类ID'},
              'isCompleted': <String, String>{'type': 'boolean', 'description': '是否已完成'},
            },
            'required': <String>['id'],
          },
        ),
        FunctionDefinition(
          name: 'delete_event',
          description: '删除指定的事件',
          parameters: const <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{
              'id': <String, String>{'type': 'string', 'description': '要删除的事件ID（必需）'},
            },
            'required': <String>['id'],
          },
        ),
        FunctionDefinition(
          name: 'get_event',
          description: '获取单个事件的详细信息',
          parameters: const <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{
              'id': <String, String>{'type': 'string', 'description': '事件ID（必需）'},
            },
            'required': <String>['id'],
          },
        ),
        FunctionDefinition(
          name: 'get_events',
          description: '获取所有事件的列表',
          parameters: const <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{
              // 无参数，获取所有事件
            },
          },
        ),
      ],
    );
  }
}
