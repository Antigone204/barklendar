import 'dart:convert';
import 'dart:developer' as developer;
import 'package:ai_smart_calendar/models/function_call.dart';
import 'package:ai_smart_calendar/services/ai_service_interface.dart';
import 'package:ai_smart_calendar/services/ai_service.dart' as static_ai;
import 'package:ai_smart_calendar/services/ai_dio.dart';
import 'package:dio/dio.dart';

/// 实例化的AI服务，支持工具调用
class AIServiceInstance implements AIService {
  final Map<String, String> config;
  final String _instanceId;

  AIServiceInstance({required this.config})
      : _instanceId =
            'AIServiceInstance_${DateTime.now().millisecondsSinceEpoch}';

  @override
  String get instanceId => _instanceId;

  /// 生成响应（支持工具调用）
  @override
  Future<AIResponse> generateResponseWithTools({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
  }) async {
    try {
      final Dio dio = AiDio.instance.dio;

      // 处理URL路径，确保使用正确的API端点
      final String apiUrl = config['url']?.endsWith('/chat/completions') == true
          ? config['url']!
          : '${config['url']}/chat/completions';

      // 构建请求体，包含工具定义
      final Map<String, Object> requestBody = <String, Object>{
        'model': config['model'] ?? 'gpt-3.5-turbo',
        'messages': messages,
        'tools': tools,
        'tool_choice': 'auto',
      };

      // ======================= 📍 日志点 1: 请求信息 =======================
      developer.log(
        '[AIService LOG] Request URL: $apiUrl',
        name: 'ai.service.debug',
      );
      developer.log(
        '[AIService LOG] Request Body: ${jsonEncode(requestBody)}',
        name: 'ai.service.debug',
      );
      // =======================================================================

      // 发送请求
      final Response<Map<String, dynamic>> response =
          await dio.post<Map<String, dynamic>>(
        apiUrl,
        options: Options(
          headers: <String, dynamic>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config['api_key']}',
          },
          validateStatus: (int? status) => true,
        ),
        data: requestBody,
      );

      // ======================= 📍 日志点 2: 原始响应 =======================
      developer.log(
        '[AIService LOG] Raw Response Status: ${response.statusCode}',
        name: 'ai.service.debug',
      );
      developer.log(
        '[AIService LOG] Raw Response Body:\n${response.data}',
        name: 'ai.service.debug',
      );
      // =======================================================================

      if (response.statusCode != 200) {
        throw Exception('API请求失败: ${response.statusCode}');
      }

      // 解码JSON响应
      final Map<String, dynamic>? data = response.data;

      // ======================= 📍 日志点 3: 解码后的类型 =======================
      developer.log(
        '[AIService LOG] Decoded data runtimeType: ${data.runtimeType}',
        name: 'ai.service.debug',
      );
      // =======================================================================

      // 提取消息对象
      final dynamic message = data?['choices']?[0]?['message'];

      // ======================= 📍 日志点 4: Message 对象的类型 =======================
      developer.log(
        '[AIService LOG] Message object runtimeType: ${message.runtimeType}',
        name: 'ai.service.debug',
      );
      // ==========================================================================

      // 检查是否有工具调用
      if (message['tool_calls'] != null) {
        final toolCalls = message['tool_calls'];

        // ======================= 📍 日志点 5: Tool Calls 对象的类型 =======================
        developer.log(
          '[AIService LOG] Tool Calls object runtimeType: ${toolCalls.runtimeType}',
          name: 'ai.service.debug',
        );
        // ===========================================================================

        final functionData = toolCalls[0]['function'];
        final String functionName = functionData['name'] as String; // 确保是字符串类型
        final dynamic rawArguments =
            functionData['arguments']; // 1. 用 dynamic 接收，因为它可能是任何类型

        // ======================= 📍 日志点 6: Function Call 数据的类型 =======================
        developer.log(
          '[AIService LOG] Function call data runtimeType: ${functionData.runtimeType}',
          name: 'ai.service.debug',
        );
        developer.log(
          '[AIService LOG] Function call arguments runtimeType: ${rawArguments.runtimeType}',
          name: 'ai.service.debug',
        );
        // =================================================================================

        Map<String, dynamic> arguments = <String, dynamic>{}; // 2. 准备一个干净的、空的Map作为默认值

        // 3. 关键的健壮性检查和转换！
        if (rawArguments is Map) {
          // 理想情况：它本身就是一个Map
          // 我们只需要安全地转换它，以防万一
          arguments = Map<String, dynamic>.from(rawArguments);
        } else if (rawArguments is String && rawArguments.isNotEmpty) {
          // 现实情况：它是一个非空字符串
          try {
            // 我们尝试把它当作JSON字符串来"拆箱"
            arguments = jsonDecode(rawArguments) as Map<String, dynamic>;
          } catch (e) {
            // 如果"拆箱"失败，记录错误，但不要让应用崩溃
            developer.log(
              'Failed to decode arguments string: $rawArguments',
              name: 'ai.service.debug',
              error: e,
            );
            // 此时 arguments 仍然是空的Map，后续的本地验证会优雅地处理这个问题
          }
        }

        // 4. 无论外部API给我们的是什么，我们传递给内部系统的，永远是一个干净的 Map<String, dynamic>
        final FunctionCall functionCall =
            FunctionCall(name: functionName, arguments: arguments);

        return AIResponse.withFunctionCall(
          functionCall,
          content: (message['content'] ?? '') as String,
        );
      } else {
        // 直接回答
        return AIResponse.directAnswer((message['content'] ?? '') as String);
      }
    } catch (e) {
      // ======================= 📍 日志点 7: 错误信息 =======================
      developer.log(
        '[AIService LOG] Error occurred: $e',
        name: 'ai.service.debug',
      );
      // =======================================================================

      // 如果工具调用失败，回退到普通响应
      final String fallbackResponse = await generateResponse(messages: messages);
      return AIResponse.directAnswer(fallbackResponse);
    }
  }

  /// 生成普通响应（不支持工具调用）
  @override
  Future<String> generateResponse({
    required List<Map<String, dynamic>> messages,
  }) async {
    try {
      final StringBuffer buffer = StringBuffer();
      final Stream<String> stream = static_ai.AiService.generateResponseWithTools(
        messages,
        config: config,
      );

      await for (final String chunk in stream) {
        buffer.write(chunk);
      }

      return buffer.toString();
    } catch (e) {
      return '抱歉，AI服务暂时不可用: $e';
    }
  }

  /// 测试连接
  @override
  Future<Map<String, dynamic>> testConnection() async {
    try {
      return await static_ai.AiService.testConnection(
        config: config,
      );
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': '连接测试失败',
        'error': e.toString(),
      };
    }
  }
}

/// AI配置键常量
class AiConfigKeys {
  static const String type = 'type';
  static const String url = 'url';
  static const String apiKey = 'api_key';
  static const String model = 'model';
  static const String temperature = 'temperature';
  static const String maxTokens = 'max_tokens';
}
