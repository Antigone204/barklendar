import 'package:ai_smart_calendar/models/function_call.dart';
import 'package:ai_smart_calendar/services/ai_service_interface.dart';

/// 未配置的AI服务实现
/// 当没有有效的AI配置时使用，提供清晰的错误信息
class UnconfiguredAIService implements AIService {
  final String _instanceId;

  UnconfiguredAIService()
      : _instanceId =
            'UnconfiguredAIService_${DateTime.now().millisecondsSinceEpoch}';

  @override
  String get instanceId => _instanceId;
  @override
  Future<AIResponse> generateResponseWithTools({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
  }) async {
    throw Exception('AI服务未配置。请先在设置中配置AI服务。');
  }

  @override
  Future<String> generateResponse({
    required List<Map<String, dynamic>> messages,
  }) async {
    return 'AI服务未配置。请先在设置中配置AI服务。';
  }

  @override
  Future<Map<String, dynamic>> testConnection() async {
    return {
      'success': false,
      'message': 'AI服务未配置',
      'error': '请先在设置中配置AI服务',
    };
  }
}
