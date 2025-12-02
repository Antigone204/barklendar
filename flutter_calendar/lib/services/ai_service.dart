import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:ai_smart_calendar/services/ai_cache.dart';
import 'package:ai_smart_calendar/services/ai_factory.dart';
import 'package:ai_smart_calendar/services/hive_service.dart';
import 'package:ai_smart_calendar/services/ai_client.dart';
import 'package:ai_smart_calendar/services/openai_client.dart';
import 'package:ai_smart_calendar/services/claude_client.dart';
import 'package:ai_smart_calendar/services/gemini_client.dart';
import 'package:ai_smart_calendar/services/deepseek_client.dart';
import 'package:ai_smart_calendar/services/generic_openai_compatible_client.dart';
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/utils/date_utils.dart';
import 'package:ai_smart_calendar/utils/intent_result.dart';
import 'package:hive/hive.dart';

class AiService {
  /// 生成带工具调用的流式响应
  static Stream<String> generateResponseWithTools(
    List<Map<String, dynamic>> messages, {
    String? identifier,
    Map<String, String>? config,
    bool regenerate = false,
    bool useCache = true,
  }) async* {
    identifier ??= HiveService.selectedAiService;
    config ??= HiveService.getAiConfig(identifier) ?? <String, String>{};
    String buffer = '';

    final String? url = config['url'];
    if (url == null || url.isEmpty) {
      yield 'AI服务未配置';
      return;
    }

    final String messagesStr = messages
        .map((Map<String, dynamic> m) => '${m['role']}: ${m['content']}')
        .join('\n');
    final int hash = messagesStr.hashCode;

    // 只有在启用缓存且不强制重新生成时才检查缓存
    if (useCache && !regenerate) {
      final String? aiCache = await AiCache.getAiCache(hash);
      if (aiCache != null && aiCache.isNotEmpty) {
        yield aiCache;
        return;
      }
    }

    try {
      final Stream<String> stream = AiFactory.generateStream(
        identifier,
        messages,
        config,
      );

      await for (final String chunk in stream) {
        // ---- 部署日志探针 ----
        if (kDebugMode) {
          print('[STREAM LOG] Raw data chunk received: $chunk');
        }
        // ---- 探针结束 ----

        buffer += chunk;
        yield chunk;
      }
    } catch (e) {
      yield 'AI请求失败: $e';
    } finally {
      if (useCache && buffer.isNotEmpty) {
        await AiCache.setAiCache(hash, buffer, identifier);
      }
    }
  }

  /// 测试AI服务连接
  static Future<Map<String, dynamic>> testConnection({
    String? identifier,
    Map<String, String>? config,
  }) async {
    identifier ??= HiveService.selectedAiService;
    config ??= HiveService.getAiConfig(identifier) ?? <String, String>{};

    final String? url = config['url'];
    if (url == null || url.isEmpty) {
      return <String, dynamic>{
        'success': false,
        'message': 'API端点未配置',
        'error': '请先配置API端点',
      };
    }

    final String? apiKey = config['api_key'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY') {
      return <String, dynamic>{
        'success': false,
        'message': 'API密钥未配置',
        'error': '请先配置有效的API密钥',
      };
    }

    try {
      // 使用AI工厂创建客户端并测试连接
      final AiClient client = _createClient(identifier, config);
      return await client.testConnection();
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': '连接测试失败',
        'error': e.toString(),
      };
    }
  }

  /// 创建AI客户端实例
  static AiClient _createClient(String identifier, Map<String, String> config) {
    // 检查配置中的type字段，如果为'generic'则使用通用客户端
    final String? type = config[AiConfigKeys.type];
    if (type == 'generic') {
      return GenericOpenAiCompatibleClient(config);
    }

    switch (identifier) {
      case 'openai':
        return OpenAiClient(config);
      case 'claude':
        return ClaudeClient(config);
      case 'gemini':
        return GeminiClient(config);
      case 'deepseek':
        return DeepSeekClient(config);
      default:
        throw Exception('Invalid AI identifier: $identifier');
    }
  }

  /// 获取Hive中的任务数据并生成AI提示
  static String generateTaskContextPrompt(String userMessage) {
    try {
      // 获取所有任务数据
      final List<TaskModel> allTasks = HiveService.getAllTasks();

      if (allTasks.isEmpty) {
        return '''你是一个智能日历助手。当前用户没有任何日程安排。

用户询问: "$userMessage"

请根据用户的提问提供友好的回应和建议。你也可以帮助用户创建新的任务，如果需要创建任务，请明确询问任务的名称和日期。''';
      }

      // 生成任务上下文
      final StringBuffer context = StringBuffer();
      context.writeln('''你是一个智能日历助手。以下是用户的日程数据：

📊 总体统计：
• 总任务数: ${allTasks.length}
• 已完成: ${allTasks.where((TaskModel t) => t.isCompleted).length}
• 待完成: ${allTasks.where((TaskModel t) => !t.isCompleted).length}
• 过期任务: ${allTasks.where((TaskModel t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(DateTime.now())).length}

📅 今日任务 (${DateUtils.formatChineseDate(DateTime.now())}):''');

      // 添加今日任务
      final DateTime today = DateTime.now();
      final List<TaskModel> todayTasks = allTasks.where((TaskModel task) {
        if (task.dueDate == null) return false;
        return task.dueDate!.year == today.year &&
            task.dueDate!.month == today.month &&
            task.dueDate!.day == today.day;
      }).toList();

      if (todayTasks.isEmpty) {
        context.writeln('• 今天没有安排任务');
      } else {
        for (final TaskModel task in todayTasks) {
          context.writeln('• ${task.isCompleted ? '✅' : '⏰'} ${task.title}');
        }
      }

      context.writeln('''
      
用户询问: "$userMessage"

请根据以上日程数据，用中文为用户提供智能、有帮助的回应。保持友好和专业的语气，提供实用的建议。

---
**重要指令：任务管理**

当用户意图是 **创建、添加或安排新任务** 时，请严格遵循以下流程：

1.  **提取核心信息**：从用户的话语中精确地提取出 **任务标题** 和 **日期时间**。
    *   **标题提取原则**：标题应该是简洁、明确的动作或事件，**绝对不能包含** 日期、时间或"创建"、"安排"等命令词。例如，对于"帮我安排明天下午三点开会"，正确的标题是"开会"。
    *   **时间提取原则**：理解相对时间（如"明天"、"后天下午"）和具体时间。

2.  **推荐具体时间**：如果用户只说了模糊的时间（如"上午"、"晚上"），你必须 **主动推荐一个具体的时间点**。例如，如果用户说"明天上午"，你可以推荐"明天上午10:00"。

3.  **生成结构化回复**：你的最终回复必须包含两部分：
    *   一个给程序解析的 **JSON数据块**。
    *   一句给用户看的 **自然语言确认**。

    **回复格式示例**:
    [AI_ACTION]
    {
      "intent": "create_task",
      "title": "开会",
      "dueDate": "2025-09-23T15:00:00" 
    }
    [/AI_ACTION]
    好的，已为您安排任务「开会」，时间是明天下午3:00，是否确认？

    如果信息不完整，无法提取标题或日期，请不要使用JSON格式，而是直接向用户提问以获取更多信息。例如："好的，您想创建什么任务呢？"
''');

      return context.toString();
    } catch (e) {
      return '''你是一个智能日历助手。获取用户日程数据时出现错误。

用户询问: "$userMessage"

请为用户提供友好的回应。''';
    }
  }

  /// 创建新任务
  static Future<Map<String, dynamic>> createTask({
    required String title,
    required DateTime dueDate,
    String description = '',
    String categoryId = 'default',
    TaskPriority priority = TaskPriority.medium,
  }) async {
    try {
      // 确保Hive已初始化
      if (!Hive.isBoxOpen('tasks')) {
        await HiveService.init();
      }

      final String taskId = DateTime.now().millisecondsSinceEpoch.toString();

      final TaskModel newTask = TaskModel(
        id: taskId,
        title: title,
        description: description,
        createdAt: DateTime.now(),
        dueDate: dueDate,
        categoryId: categoryId,
        priority: priority,
      );

      await HiveService.addTask(newTask);

      // 验证任务是否真的添加成功
      final TaskModel? addedTask = HiveService.getTask(taskId);
      if (addedTask == null) {
        return <String, dynamic>{
          'success': false,
          'message': '任务创建失败：无法验证任务是否保存成功',
          'task': null,
        };
      }

      return <String, dynamic>{
        'success': true,
        'message': '任务创建成功',
        'task': newTask,
      };
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': '创建任务失败: $e',
        'task': null,
      };
    }
  }

  /// 更新任务
  static Future<Map<String, dynamic>> updateTask(TaskModel task) async {
    try {
      await HiveService.updateTask(task);

      return <String, dynamic>{
        'success': true,
        'message': '任务更新成功',
        'task': task,
      };
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': '更新任务失败: $e',
        'task': null,
      };
    }
  }

  /// 删除任务
  static Future<Map<String, dynamic>> deleteTask(String taskId) async {
    try {
      await HiveService.deleteTask(taskId);

      return <String, dynamic>{
        'success': true,
        'message': '任务删除成功',
      };
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': '删除任务失败: $e',
      };
    }
  }

  /// 标记任务为完成/未完成
  static Future<Map<String, dynamic>> toggleTaskCompletion(
    String taskId,
    bool completed,
  ) async {
    try {
      final TaskModel? task = HiveService.getTask(taskId);
      if (task == null) {
        return <String, dynamic>{
          'success': false,
          'message': '找不到指定的任务',
        };
      }

      final TaskModel updatedTask = task.copyWith(
        isCompleted: completed,
        completedAt: completed ? DateTime.now() : null,
      );

      await HiveService.updateTask(updatedTask);

      return <String, dynamic>{
        'success': true,
        'message': completed ? '任务标记为已完成' : '任务标记为未完成',
        'task': updatedTask,
      };
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': '更新任务状态失败: $e',
        'task': null,
      };
    }
  }

  /// 根据标题搜索任务
  static List<TaskModel> searchTasks(String query) {
    final List<TaskModel> allTasks = HiveService.getAllTasks();
    return allTasks
        .where((TaskModel task) =>
            task.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// 获取指定日期的任务
  static List<TaskModel> getTasksByDate(DateTime date) {
    return HiveService.getTasksByDate(date);
  }

  /// 解析用户意图并返回一个结构化的结果（新版）
  static Future<IntentResult> processUserIntent(
    String userMessage,
    String aiResponse,
  ) async {
    try {
      final RegExp actionRegex =
          RegExp(r'\[AI_ACTION\]\s*(\{.*?\})\s*\[/AI_ACTION\]', dotAll: true);
      final Match? match = actionRegex.firstMatch(aiResponse);

      final String naturalResponse =
          aiResponse.replaceAll(actionRegex, '').trim();

      if (match == null) {
        return GeneralResponse(aiResponse);
      }

      final String jsonStr = match.group(1)!;
      final Map<String, dynamic> actionData =
          jsonDecode(jsonStr) as Map<String, dynamic>;

      if (actionData['intent'] == 'create_task') {
        final String title = actionData['title'] as String;
        final DateTime dueDate =
            DateTime.parse(actionData['dueDate'] as String);
        final TaskModel newTask = TaskModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          description: '由AI助手创建',
          dueDate: dueDate,
          createdAt: DateTime.now(),
          categoryId: 'default',
        );
        return CreateTaskSuccess(
          '$naturalResponse\n\n✅ 任务已为您准备好！',
          newTask,
        );
      }

      return GeneralResponse(naturalResponse);
    } catch (e) {
      return IntentError('$aiResponse\n\n⚠️ 处理您的指令时出现错误: $e');
    }
  }
}
