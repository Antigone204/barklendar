import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/models/chat_message.dart';
import 'package:ai_smart_calendar/models/function_call.dart';
import 'package:ai_smart_calendar/models/tool_call_request.dart';
import 'package:ai_smart_calendar/models/tool_call_response.dart';
import 'package:ai_smart_calendar/models/ai_turn_state.dart';
import 'package:ai_smart_calendar/services/ai_service_interface.dart';
import 'package:ai_smart_calendar/services/calendar_tool_service.dart';
import 'package:ai_smart_calendar/services/tool_registry_service.dart';
import 'package:ai_smart_calendar/providers/repository_providers.dart';

/// 核心调度器 - AI交互的中枢神经系统
class ToolCallingService {
  final Ref _ref;
  final ToolRegistryService _toolRegistry;
  final CalendarToolService _calendarToolService;

  ToolCallingService({
    required Ref ref,
    required ToolRegistryService toolRegistry,
    required CalendarToolService calendarToolService,
  })  : _ref = ref,
        _toolRegistry = toolRegistry,
        _calendarToolService = calendarToolService;

  /// 核心方法：执行一次完整的AI交互回合（向后兼容版本）
  /// 实现"思考-行动-总结"循环
  Future<String> executeTurn(String userMessage,
      {List<ChatMessage> history = const []}) async {
    try {
      // 步骤1: 准备工具定义
      final toolSchemas = _toolRegistry.generateToolSchemas();

      // 步骤2: 构建思考阶段的系统提示
      final String currentTime = DateTime.now().toIso8601String();
      final thinkingSystemPrompt = '''
你是一个智能日历助手。你可以使用以下工具来帮助用户：

## 当前上下文
- 当前日期和时间是: $currentTime

${_toolRegistry.generateToolPrompt()}

## 使用说明
请根据用户请求决定：
- 如果可以直接回答，请直接回复
- 如果需要使用工具，请调用相应的函数
- 在调用工具前，请务必从**完整的对话历史**中，提取所有必需的参数
- 如果缺少任何必需参数，你应该**首先向用户提问**以获取信息，而不是直接调用工具

请用中文回复用户。
''';

      // 步骤3: 构建消息历史
      final messages = [
        ChatMessage(
            role: 'system',
            content: thinkingSystemPrompt,
            timestamp: DateTime.now()),
        ...history,
        ChatMessage(
            role: 'user', content: userMessage, timestamp: DateTime.now()),
      ];

      // 步骤4: 首次LLM调用 - 思考阶段
      final aiService = _ref.read(aiServiceProvider);
      final thinkingResponse = await aiService.generateResponseWithTools(
        messages: messages.map((m) => m.toOpenAIMessage()).toList(),
        tools: toolSchemas,
      );

      // 步骤5: 分析响应
      if (thinkingResponse.isDirectAnswer) {
        // 情况A: 直接回答
        return thinkingResponse.content;
      } else if (thinkingResponse.hasFunctionCall) {
        // 情况B: 需要工具调用
        return await _handleFunctionCall(
            thinkingResponse.functionCall!, userMessage, history);
      } else {
        // 意外情况，返回原始响应
        return thinkingResponse.content;
      }
    } catch (e) {
      return '抱歉，处理您的请求时发生了错误: $e';
    }
  }

  /// 处理工具调用的私有方法
  Future<String> _handleFunctionCall(
    FunctionCall functionCall,
    String userMessage,
    List<ChatMessage> history,
  ) async {
    try {
      // 步骤1: 验证函数调用
      final validation = _toolRegistry.validateFunctionParameters(
        functionCall.name,
        functionCall.arguments,
      );

      if (validation?['valid'] != true) {
        return '抱歉，工具调用参数验证失败: ${validation?['error']}';
      }

      // 步骤2: 执行工具调用
      ToolCallResponse toolResponse;
      try {
        final request = ToolCallRequest(
          toolName: _getToolNameFromFunction(functionCall.name),
          functionName: functionCall.name,
          parameters: functionCall.arguments,
        );

        // 根据工具名称路由到相应的服务
        toolResponse = await _routeToolCall(request);
      } catch (e) {
        return '执行工具时发生错误: $e';
      }

      // 步骤3: 构建总结阶段的系统提示
      final summarizingSystemPrompt = '''
你是一个智能日历助手。你刚刚执行了一个工具调用，现在需要将执行结果用自然语言总结给用户。

工具执行结果: ${toolResponse.isSuccess ? '成功' : '失败'}
${toolResponse.isSuccess ? '结果数据: ${toolResponse.result}' : '错误信息: ${toolResponse.error}'}

请用友好的中文向用户总结这个结果，保持自然流畅。
''';

      // 步骤4: 二次LLM调用 - 总结阶段
      final summarizingMessages = [
        ChatMessage(
            role: 'system',
            content: summarizingSystemPrompt,
            timestamp: DateTime.now()),
        ChatMessage(
            role: 'user', content: userMessage, timestamp: DateTime.now()),
        ChatMessage(
          role: 'assistant',
          content: '我已经执行了您请求的操作。',
          timestamp: DateTime.now(),
        ),
      ];

      final aiService = _ref.read(aiServiceProvider);
      final summarizingResponse = await aiService.generateResponse(
        messages: summarizingMessages.map((m) => m.toOpenAIMessage()).toList(),
      );

      return summarizingResponse;
    } catch (e) {
      return '处理工具调用时发生错误: $e';
    }
  }

  /// 核心方法：执行一次完整的AI交互回合（流式版本）
  /// 升级为支持多次工具调用的自主循环架构
  Stream<AiTurnState> executeTurnStream(String userMessage,
      {List<ChatMessage> history = const []}) async* {
    // ======================= 📍 日志点 A: 方法入口 =======================
    developer.log('[TCS LOG] A: executeTurnStream entered.', name: 'tcs.debug');
    // ===================================================================

    // 1. 将完整的对话历史（包括最新消息）放入一个可变列表中
    final List<ChatMessage> conversationHistory = [
      ...history,
      ChatMessage(
          role: 'user', content: userMessage, timestamp: DateTime.now()),
    ];

    const maxTurns = 5; // 设定一个最大循环次数，防止无限循环

    try {
      yield const AiTurnStateThinking();

      for (int turn = 0; turn < maxTurns; turn++) {
        // ======================= 📍 日志点 B: 循环开始 =======================
        developer.log('[TCS LOG] B: Starting turn $turn of $maxTurns',
            name: 'tcs.debug');
        // ===================================================================

        // 2. 准备工具和系统提示
        final toolSchemas = _toolRegistry.generateToolSchemas();
        final systemPrompt = _buildSystemPrompt();

        final messagesForApi = [
          ChatMessage(
              role: 'system', content: systemPrompt, timestamp: DateTime.now()),
          ...conversationHistory, // 每次都发送完整的历史
        ];

        // ======================= 📍 日志点 C: 即将调用AI服务 =======================
        developer.log(
            '[TCS LOG] C: About to call _aiService.generateResponseWithTools...',
            name: 'tcs.debug');
        // =========================================================================

        // 在运行时获取最新的AIService实例
        final aiService = _ref.read(aiServiceProvider);
        final response = await aiService.generateResponseWithTools(
          messages: messagesForApi.map((m) => m.toOpenAIMessage()).toList(),
          tools: toolSchemas,
        );

        // ======================= 📍 日志点 D: AI服务调用已返回 =======================
        developer.log(
            '[TCS LOG] D: _aiService.generateResponseWithTools returned.',
            name: 'tcs.debug');
        developer.log(
            '[TCS LOG] D-1: Response isDirectAnswer: ${response.isDirectAnswer}',
            name: 'tcs.debug');
        developer.log(
            '[TCS LOG] D-2: Response hasFunctionCall: ${response.hasFunctionCall}',
            name: 'tcs.debug');
        // ==========================================================================

        if (response.isDirectAnswer) {
          // 4. 如果AI决定直接回答，说明任务已完成或需要用户输入，循环结束
          // ======================= 📍 日志点 E: 进入直接回答分支 =======================
          developer.log('[TCS LOG] E: Entering direct answer branch.',
              name: 'tcs.debug');
          // ========================================================================
          yield* _streamDirectResponse(response.content);
          return; // 退出循环
        }

        if (response.hasFunctionCall) {
          // 5. 如果AI决定调用工具
          // ======================= 📍 日志点 F: 进入工具调用分支 =======================
          developer.log('[TCS LOG] F: Entering function call branch.',
              name: 'tcs.debug');
          // ========================================================================

          yield AiTurnStateCallingTool(
            toolName: _getToolNameFromFunction(response.functionCall!.name),
            functionName: response.functionCall!.name,
            parameters: response.functionCall!.arguments,
          );

          // 执行工具
          final toolResponse =
              await _handleFunctionCallInLoop(response.functionCall!);

          // 6. 关键一步：将工具执行的结果作为一个新的"assistant"消息，
          //    添加到对话历史中，用于下一次循环！
          conversationHistory.add(ChatMessage(
            role: 'assistant',
            content: toolResponse.isSuccess
                ? 'Tool call successful. Result: ${toolResponse.result}'
                : 'Tool call failed. Error: ${toolResponse.error}',
            timestamp: DateTime.now(),
          ));

          // 继续下一次循环，让AI看到工具执行结果后，再决定下一步做什么
        }
      }

      // 如果循环结束仍未完成，给出一个提示
      yield const AiTurnStateError(
          message: "AI seems to be in a loop. Aborting.");
    } catch (e, stackTrace) {
      // ======================= 📍 日志点 H: 捕获到异常 =======================
      developer.log('[TCS LOG] H: Caught an exception!',
          name: 'tcs.debug', error: e, stackTrace: stackTrace);
      // ====================================================================
      yield AiTurnStateError(message: '抱歉，处理您的请求时发生了错误: $e');
    }
  }

  /// 流式处理直接响应
  Stream<AiTurnState> _streamDirectResponse(String content) async* {
    // 模拟流式输出（实际中应从AI服务获取流）
    final words = content.split(' ');
    for (int i = 0; i < words.length; i++) {
      final chunk = words.sublist(0, i + 1).join(' ');
      yield AiTurnStateStreamingContent(
        contentChunk: chunk,
        isComplete: i == words.length - 1,
      );
      await Future.delayed(const Duration(milliseconds: 50)); // 模拟打字机效果
    }

    yield AiTurnStateCompleted(finalContent: content);
  }

  /// 流式处理工具调用
  Stream<AiTurnState> _handleFunctionCallWithStream(
    FunctionCall functionCall,
    String userMessage,
    List<ChatMessage> history,
  ) async* {
    // 1. 告诉UI"我正在使用工具"
    yield AiTurnStateCallingTool(
      toolName: _getToolNameFromFunction(functionCall.name),
      functionName: functionCall.name,
      parameters: functionCall.arguments,
    );

    // 2. 验证函数调用
    final validation = _toolRegistry.validateFunctionParameters(
      functionCall.name,
      functionCall.arguments,
    );

    if (validation?['valid'] != true) {
      yield AiTurnStateError(message: '工具调用参数验证失败: ${validation?['error']}');
      return;
    }

    // 3. 执行工具调用
    ToolCallResponse toolResponse;
    try {
      final request = ToolCallRequest(
        toolName: _getToolNameFromFunction(functionCall.name),
        functionName: functionCall.name,
        parameters: functionCall.arguments,
      );
      toolResponse = await _routeToolCall(request);
    } catch (e) {
      yield AiTurnStateError(message: '执行工具时发生错误: $e');
      return;
    }

    // 4. 构建总结阶段的系统提示
    final summarizingSystemPrompt = '''
你是一个智能日历助手。你刚刚执行了一个工具调用，现在需要将执行结果用自然语言总结给用户。

工具执行结果: ${toolResponse.isSuccess ? '成功' : '失败'}
${toolResponse.isSuccess ? '结果数据: ${toolResponse.result}' : '错误信息: ${toolResponse.error}'}

请用友好的中文向用户总结这个结果，保持自然流畅。
''';

    // 5. 二次LLM调用 - 总结阶段，流式输出
    final summarizingMessages = [
      ChatMessage(
          role: 'system',
          content: summarizingSystemPrompt,
          timestamp: DateTime.now()),
      ChatMessage(
          role: 'user', content: userMessage, timestamp: DateTime.now()),
      ChatMessage(
        role: 'assistant',
        content: '我已经执行了您请求的操作。',
        timestamp: DateTime.now(),
      ),
    ];

    // 模拟流式总结输出
    final aiService = _ref.read(aiServiceProvider);
    final summaryContent = await aiService.generateResponse(
      messages: summarizingMessages.map((m) => m.toOpenAIMessage()).toList(),
    );

    yield* _streamDirectResponse(summaryContent);
  }

  /// 工具调用路由方法
  Future<ToolCallResponse> _routeToolCall(ToolCallRequest request) async {
    switch (request.toolName) {
      case 'calendar':
        return await _calendarToolService.handleCall(request);
      // 未来添加新工具时，在这里添加路由逻辑
      // case 'weather':
      //   return await _weatherToolService.handleCall(request);
      default:
        return ToolCallResponse.error(
          toolName: request.toolName,
          functionName: request.functionName,
          error: '未知的工具: ${request.toolName}',
        );
    }
  }

  /// 根据函数名推断工具名
  String _getToolNameFromFunction(String functionName) {
    // 目前只有日历工具，未来可以建立更复杂的映射关系
    return 'calendar';
  }

  /// 构建系统提示的私有方法
  String _buildSystemPrompt() {
    final String currentTime = DateTime.now().toIso8601String();
    return '''
你是一个智能日历助手。你可以使用以下工具来帮助用户：

## 当前上下文
- 当前日期和时间是: $currentTime

${_toolRegistry.generateToolPrompt()}

## 自主循环使用说明
你是一个自主的AI代理，可以连续调用工具直到任务完成。

### 工作流程：
1. 分析用户请求，确定需要执行的操作
2. 如果可以直接回答，请直接回复
3. 如果需要使用工具，请调用相应的函数
4. 在调用工具前，请务必从**完整的对话历史**中，提取所有必需的参数
5. 如果缺少任何必需参数，你应该**首先向用户提问**以获取信息，而不是直接调用工具
6. 工具执行后，你会看到执行结果，然后决定下一步操作
7. 重复步骤2-6，直到任务完成

### 重要规则：
- 每次只能调用一个工具
- 仔细阅读工具执行结果，根据结果决定下一步
- 如果任务已经完成，请直接回复用户总结结果
- 如果遇到错误，请分析错误原因并决定是否重试或询问用户

请用中文回复用户。
''';
  }

  /// 处理循环中的工具调用
  Future<ToolCallResponse> _handleFunctionCallInLoop(
      FunctionCall functionCall) async {
    try {
      // 验证函数调用
      final validation = _toolRegistry.validateFunctionParameters(
        functionCall.name,
        functionCall.arguments,
      );

      if (validation?['valid'] != true) {
        return ToolCallResponse.error(
          toolName: _getToolNameFromFunction(functionCall.name),
          functionName: functionCall.name,
          error: '工具调用参数验证失败: ${validation?['error']}',
        );
      }

      // 执行工具调用
      final request = ToolCallRequest(
        toolName: _getToolNameFromFunction(functionCall.name),
        functionName: functionCall.name,
        parameters: functionCall.arguments,
      );

      return await _routeToolCall(request);
    } catch (e) {
      return ToolCallResponse.error(
        toolName: _getToolNameFromFunction(functionCall.name),
        functionName: functionCall.name,
        error: '执行工具时发生错误: $e',
      );
    }
  }

  /// 获取服务统计信息（用于调试和监控）
  Map<String, dynamic> getServiceStatistics() {
    final toolStats = _toolRegistry.getToolStatistics();
    return {
      'toolCallingService': {
        'availableTools': toolStats['totalTools'],
        'availableFunctions': toolStats['totalFunctions'],
        'registeredTools': toolStats['tools'],
      },
    };
  }
}
