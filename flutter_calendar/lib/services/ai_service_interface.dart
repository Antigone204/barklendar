import 'package:ai_smart_calendar/models/function_call.dart';

/// AI服务接口定义
abstract class AIService {
  /// 实例唯一标识符，用于调试和追踪
  String get instanceId;

  /// 生成响应（支持工具调用）
  Future<AIResponse> generateResponseWithTools({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
  });

  /// 生成普通响应（不支持工具调用）
  Future<String> generateResponse({
    required List<Map<String, dynamic>> messages,
  });

  /// 测试连接
  Future<Map<String, dynamic>> testConnection();
}
