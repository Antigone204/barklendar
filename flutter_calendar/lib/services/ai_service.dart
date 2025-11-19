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
import 'package:ai_smart_calendar/services/tool_registry_service.dart';
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/utils/date_utils.dart';
import 'package:ai_smart_calendar/utils/intent_result.dart';
import 'package:hive/hive.dart';

class AiService {
  static Stream<String> generateResponseWithTools(
    List<Map<String, dynamic>> messages, {
    String? identifier,
    Map<String, String>? config,
    bool regenerate = false,
    bool useCache = true, // 新增参数控制是否使用缓存
  }) async* {
    identifier ??= HiveService.selectedAiService;
    config ??= HiveService.getAiConfig(identifier) ?? {};
    String buffer = '';

    final url = config['url'];
    if (url == null || url.isEmpty) {
      yield 'AI服务未配置';
      return;
    }

    final messagesStr =
        messages.map((m) => '${m['role']}: ${m['content']}').join('\n');
    final hash = messagesStr.hashCode;

    // 只有在启用缓存且不强制重新生成时才检查缓存
    if (useCache && !regenerate) {
      final aiCache = await AiCache.getAiCache(hash);
      if (aiCache != null && aiCache.isNotEmpty) {
        yield aiCache;
        return;
      }
    }

    try {
      // 从配置中获取必要参数
      final modelId = config['model'] ?? 'gpt-3.5-turbo';
      final toolsList = ToolRegistryService().generateToolSchemas();

      final requestBody = {
        'model': modelId,
        'messages': messages,
        'tools': toolsList,
        'tool_choice': 'auto',
        'stream': true,
      };

      Stream<String> stream = AiFactory.generateStream(
        identifier,
        messages,
        config,
      );

      await for (final chunk in stream) {
        // ---- 部署日志探针 ----
        if (kDebugMode) {
          print('[STREAM LOG] Raw data chunk received: $chunk');
        }
        // ---- 探针结束 ----

        buffer += chunk;
        yield chunk; // 改为逐块输出而不是累积buffer
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
    config ??= HiveService.getAiConfig(identifier) ?? {};

    final url = config['url'];
    if (url == null || url.isEmpty) {
      return {
        'success': false,
        'message': 'API端点未配置',
        'error': '请先配置API端点',
      };
    }

    final apiKey = config['api_key'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY') {
      return {
        'success': false,
        'message': 'API密钥未配置',
        'error': '请先配置有效的API密钥',
      };
    }

    try {
      // 使用AI工厂创建客户端并测试连接
      final client = _createClient(identifier, config);
      return await client.testConnection();
    } catch (e) {
      return {
        'success': false,
        'message': '连接测试失败',
        'error': e.toString(),
      };
    }
  }

  /// 创建AI客户端实例
  static AiClient _createClient(String identifier, Map<String, String> config) {
    // 检查配置中的type字段，如果为'generic'则使用通用客户端
    final type = config[AiConfigKeys.type];
    if (type == 'generic') {
      return GenericOpenAiCompatibleClient(config);
    }

    switch (identifier) {
      case "openai":
        return OpenAiClient(config);
      case "claude":
        return ClaudeClient(config);
      case "gemini":
        return GeminiClient(config);
      case "deepseek":
        return DeepSeekClient(config);
      default:
        throw Exception("Invalid AI identifier: $identifier");
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
• 已完成: ${allTasks.where((t) => t.isCompleted).length}
• 待完成: ${allTasks.where((t) => !t.isCompleted).length}
• 过期任务: ${allTasks.where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(DateTime.now())).length}

📅 今日任务 (${DateUtils.formatChineseDate(DateTime.now())}):''');

      // 添加今日任务
      final DateTime today = DateTime.now();
      final List<TaskModel> todayTasks = allTasks.where((task) {
        if (task.dueDate == null) return false;
        return task.dueDate!.year == today.year &&
            task.dueDate!.month == today.month &&
            task.dueDate!.day == today.day;
      }).toList();

      if (todayTasks.isEmpty) {
        context.writeln('• 今天没有安排任务');
      } else {
        for (final task in todayTasks) {
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
        return {
          'success': false,
          'message': '任务创建失败：无法验证任务是否保存成功',
          'task': null,
        };
      }

      return {
        'success': true,
        'message': '任务创建成功',
        'task': newTask,
      };
    } catch (e) {
      return {
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

      return {
        'success': true,
        'message': '任务更新成功',
        'task': task,
      };
    } catch (e) {
      return {
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

      return {
        'success': true,
        'message': '任务删除成功',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '删除任务失败: $e',
      };
    }
  }

  /// 标记任务为完成/未完成
  static Future<Map<String, dynamic>> toggleTaskCompletion(
      String taskId, bool completed) async {
    try {
      final TaskModel? task = HiveService.getTask(taskId);
      if (task == null) {
        return {
          'success': false,
          'message': '找不到指定的任务',
        };
      }

      final TaskModel updatedTask = task.copyWith(
        isCompleted: completed,
        completedAt: completed ? DateTime.now() : null,
      );

      await HiveService.updateTask(updatedTask);

      return {
        'success': true,
        'message': completed ? '任务标记为已完成' : '任务标记为未完成',
        'task': updatedTask,
      };
    } catch (e) {
      return {
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
        .where((task) => task.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// 获取指定日期的任务
  static List<TaskModel> getTasksByDate(DateTime date) {
    return HiveService.getTasksByDate(date);
  }

  /// 解析用户意图并返回一个结构化的结果（新版）
  static Future<IntentResult> processUserIntent(
      String userMessage, String aiResponse) async {
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
        final newTask = TaskModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          description: '由AI助手创建',
          dueDate: dueDate,
          createdAt: DateTime.now(),
          categoryId: 'default',
          priority: TaskPriority.medium,
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

  /// 生成今天的日程响应
  static String _generateTodayResponse(List<TaskModel> allTasks) {
    final DateTime today = DateTime.now();
    final List<TaskModel> todayTasks = allTasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == today.year &&
          task.dueDate!.month == today.month &&
          task.dueDate!.day == today.day;
    }).toList();

    if (todayTasks.isEmpty) {
      return '🎉 今天没有安排任何任务！\n\n您可以：\n• 添加新的任务\n• 规划明天的日程\n• 享受空闲时间';
    }

    final String dateStr = DateUtils.formatChineseDate(today);
    final StringBuffer response = StringBuffer();
    response.writeln('📅 $dateStr 的日程安排：\n');

    int completedCount = 0;
    int pendingCount = 0;

    for (final task in todayTasks) {
      if (task.isCompleted) {
        response.writeln('✅ ${task.title}');
        completedCount++;
      } else {
        response.writeln('⏰ ${task.title}');
        pendingCount++;
      }
    }

    response.writeln('\n📊 统计：');
    response.writeln('• 已完成: $completedCount 个任务');
    response.writeln('• 待完成: $pendingCount 个任务');
    response.writeln('• 总计: ${todayTasks.length} 个任务');

    if (pendingCount > 0) {
      response.writeln('\n💡 建议：优先完成重要的待办事项！');
    }

    return response.toString();
  }

  /// 生成明天的日程响应
  static String _generateTomorrowResponse(List<TaskModel> allTasks) {
    final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    final List<TaskModel> tomorrowTasks = allTasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == tomorrow.year &&
          task.dueDate!.month == tomorrow.month &&
          task.dueDate!.day == tomorrow.day;
    }).toList();

    if (tomorrowTasks.isEmpty) {
      return '📅 明天还没有安排任何任务！\n\n建议：\n• 提前规划明天的日程\n• 设置重要任务的提醒\n• 保持工作生活平衡';
    }

    final String dateStr = DateUtils.formatChineseDate(tomorrow);
    final StringBuffer response = StringBuffer();
    response.writeln('📅 $dateStr 的日程安排：\n');

    for (final task in tomorrowTasks) {
      response.writeln('📌 ${task.title}');
      if (task.description != null && task.description!.isNotEmpty) {
        response.writeln('   📝 ${task.description}');
      }
    }

    response.writeln('\n💡 提醒：明天共有 ${tomorrowTasks.length} 个任务需要完成');
    return response.toString();
  }

  /// 生成本周的日程响应
  static String _generateThisWeekResponse(List<TaskModel> allTasks) {
    final DateTime now = DateTime.now();
    final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    final List<TaskModel> weekTasks = allTasks.where((task) {
      if (task.dueDate == null) return false;
      return !task.dueDate!.isBefore(startOfWeek) &&
          !task.dueDate!.isAfter(endOfWeek);
    }).toList();

    if (weekTasks.isEmpty) {
      return '📅 本周还没有安排任何任务！\n\n建议：\n• 制定周计划\n• 设置长期目标\n• 合理安排时间';
    }

    final Map<int, List<TaskModel>> tasksByDay = {};
    for (final task in weekTasks) {
      final int weekday = task.dueDate!.weekday;
      tasksByDay.putIfAbsent(weekday, () => []).add(task);
    }

    final StringBuffer response = StringBuffer();
    response.writeln(
        '📅 本周日程安排（${DateUtils.formatChineseDate(startOfWeek)} - ${DateUtils.formatChineseDate(endOfWeek)}）：\n');

    for (int day = 1; day <= 7; day++) {
      final List<TaskModel>? dayTasks = tasksByDay[day];
      if (dayTasks != null && dayTasks.isNotEmpty) {
        final DateTime dayDate = startOfWeek.add(Duration(days: day - 1));
        response.writeln(
            '${_getWeekdayEmoji(day)} ${DateUtils.formatChineseDate(dayDate)}：');
        for (final task in dayTasks) {
          response.writeln('   ${task.isCompleted ? '✅' : '⏰'} ${task.title}');
        }
        response.writeln('');
      }
    }

    response.writeln('📊 本周统计：');
    response.writeln('• 总任务数: ${weekTasks.length}');
    response.writeln('• 已完成: ${weekTasks.where((t) => t.isCompleted).length}');
    response.writeln('• 待完成: ${weekTasks.where((t) => !t.isCompleted).length}');

    return response.toString();
  }

  /// 生成所有任务的响应
  static String _generateAllTasksResponse(List<TaskModel> allTasks) {
    if (allTasks.isEmpty) {
      return '📋 目前没有任何任务！\n\n您可以：\n• 创建新的任务\n• 导入现有日程\n• 设置提醒事项';
    }

    final StringBuffer response = StringBuffer();
    response.writeln('📋 所有任务统计：\n');

    response.writeln('📊 总体情况：');
    response.writeln('• 总任务数: ${allTasks.length}');
    response.writeln('• 已完成: ${allTasks.where((t) => t.isCompleted).length}');
    response.writeln('• 待完成: ${allTasks.where((t) => !t.isCompleted).length}');
    response.writeln(
        '• 过期任务: ${allTasks.where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(DateTime.now())).length}');

    // 按分类统计
    final Map<String, int> tasksByCategory = {};
    for (final task in allTasks) {
      tasksByCategory.update(
        task.categoryId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    if (tasksByCategory.isNotEmpty) {
      response.writeln('\n🏷️ 按分类统计：');
      tasksByCategory.forEach((categoryId, count) {
        response.writeln('• $categoryId: $count 个任务');
      });
    }

    return response.toString();
  }

  /// 生成已完成任务的响应
  static String _generateCompletedTasksResponse(List<TaskModel> allTasks) {
    final List<TaskModel> completedTasks =
        allTasks.where((t) => t.isCompleted).toList();

    if (completedTasks.isEmpty) {
      return '✅ 目前没有已完成的任务！\n\n建议：\n• 开始完成一些任务\n• 设置可实现的目标\n• 庆祝每一个小成就';
    }

    final StringBuffer response = StringBuffer();
    response.writeln('✅ 已完成的任务：\n');

    for (final task in completedTasks.take(10)) {
      response.writeln('• ${task.title}');
      if (task.dueDate != null) {
        response.writeln('   📅 ${DateUtils.formatChineseDate(task.dueDate!)}');
      }
    }

    if (completedTasks.length > 10) {
      response.writeln('\n... 还有 ${completedTasks.length - 10} 个已完成的任务');
    }

    response.writeln('\n🎉 恭喜您完成了 ${completedTasks.length} 个任务！');
    return response.toString();
  }

  /// 生成待完成任务的响应
  static String _generatePendingTasksResponse(List<TaskModel> allTasks) {
    final List<TaskModel> pendingTasks =
        allTasks.where((t) => !t.isCompleted).toList();

    if (pendingTasks.isEmpty) {
      return '🎊 太棒了！所有任务都已完成！\n\n您可以：\n• 创建新的挑战\n• 休息一下\n• 回顾已完成的任务';
    }

    final StringBuffer response = StringBuffer();
    response.writeln('⏰ 待完成的任务：\n');

    // 按截止日期排序
    pendingTasks.sort((a, b) {
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    for (final task in pendingTasks.take(10)) {
      final String dueInfo = task.dueDate != null
          ? ' (📅 ${DateUtils.formatChineseDate(task.dueDate!)})'
          : ' (无截止日期)';
      response.writeln('• ${task.title}$dueInfo');
    }

    if (pendingTasks.length > 10) {
      response.writeln('\n... 还有 ${pendingTasks.length - 10} 个待完成的任务');
    }

    response.writeln('\n💪 加油！您还有 ${pendingTasks.length} 个任务需要完成');
    return response.toString();
  }

  /// 生成过期任务的响应
  static String _generateOverdueTasksResponse(List<TaskModel> allTasks) {
    final DateTime now = DateTime.now();
    final List<TaskModel> overdueTasks = allTasks
        .where((task) =>
            !task.isCompleted &&
            task.dueDate != null &&
            task.dueDate!.isBefore(now))
        .toList();

    if (overdueTasks.isEmpty) {
      return '✅ 太好了！没有过期任务！\n\n继续保持良好的时间管理习惯！';
    }

    final StringBuffer response = StringBuffer();
    response.writeln('⚠️ 过期任务：\n');

    for (final task in overdueTasks) {
      final String overdueDays = _calculateOverdueDays(task.dueDate!, now);
      response.writeln('• ${task.title} (已过期 $overdueDays)');
    }

    response.writeln('\n🚨 您有 ${overdueTasks.length} 个任务已过期');
    response.writeln('💡 建议：优先处理这些过期任务！');
    return response.toString();
  }

  /// 生成通用响应
  static String _generateGeneralResponse(
      List<TaskModel> allTasks, String userMessage) {
    final int totalTasks = allTasks.length;
    final int completedTasks = allTasks.where((t) => t.isCompleted).length;
    final int pendingTasks = totalTasks - completedTasks;
    final int overdueTasks = allTasks
        .where((task) =>
            !task.isCompleted &&
            task.dueDate != null &&
            task.dueDate!.isBefore(DateTime.now()))
        .length;

    return '''根据您的日程数据，我为您提供以下信息：

📊 总体统计：
• 总任务数: $totalTasks
• 已完成: $completedTasks
• 待完成: $pendingTasks
• 过期任务: $overdueTasks

💡 基于您的提问 "$userMessage"，我建议：

1. 使用具体的关键词获取更详细的信息，例如：
   - "今天的日程"
   - "本周的任务"  
   - "已完成的任务"
   - "待完成的任务"

2. 我可以帮您：
   • 分析时间使用情况
   • 提供任务规划建议
   • 生成智能提醒
   • 总结日程安排

请告诉我您具体想了解什么，我会为您提供更精准的帮助！''';
  }

  /// 获取星期几的表情符号
  static String _getWeekdayEmoji(int weekday) {
    switch (weekday) {
      case 1:
        return '周一 📅';
      case 2:
        return '周二 📅';
      case 3:
        return '周三 📅';
      case 4:
        return '周四 📅';
      case 5:
        return '周五 📅';
      case 6:
        return '周六 🎉';
      case 7:
        return '周日 🌞';
      default:
        return '📅';
    }
  }

  /// 计算过期天数
  static String _calculateOverdueDays(DateTime dueDate, DateTime now) {
    final difference = now.difference(dueDate);
    final days = difference.inDays;
    if (days == 0) {
      return '今天';
    } else if (days == 1) {
      return '1天';
    } else {
      return '$days天';
    }
  }
}
