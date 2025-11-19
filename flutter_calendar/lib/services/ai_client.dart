import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:ai_smart_calendar/services/ai_dio.dart';

/// AI配置键常量类，避免使用魔法字符串
class AiConfigKeys {
  static const String url = 'url';
  static const String apiKey = 'api_key';
  static const String model = 'model';
  static const String type = 'type'; // 用于工厂判断客户端类型
}

abstract class AiClient {
  final Map<String, String> config;

  AiClient(this.config);

  String get url => config['url'] ?? '';
  String get apiKey => config['api_key'] ?? '';
  String get model => config['model'] ?? '';

  Map<String, String> getHeaders();

  String? extractContent(Map<String, dynamic> json);

  bool isDone(String data) => data.trim() == '[DONE]';

  Map<String, dynamic> generateRequestBody(
      List<Map<String, dynamic>> messages) {
    return {
      'model': model,
      'messages': messages,
      'stream': true,
    };
  }

  FutureOr<String?> processLine(String line) async {
    if (line.trim().isEmpty) return null;

    if (line.startsWith('data: ')) {
      final data = line.substring(6);
      if (isDone(data)) return null;

      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final content = extractContent(json);
        return content;
      } catch (e) {
        throw Exception('Parse error: $e\nData: $data');
      }
    }
    return null;
  }

  Stream<String> generateStream(List<Map<String, dynamic>> messages);

  /// 测试AI服务连接
  Future<Map<String, dynamic>> testConnection() async {
    final dio = AiDio.instance.dio;

    try {
      // 发送一个简单的测试消息
      final testMessages = [
        {
          'role': 'user',
          'content': 'Hello, please respond with "OK" to confirm connection.'
        }
      ];

      // 处理URL路径，确保使用正确的API端点
      final apiUrl =
          url.endsWith('/chat/completions') ? url : '$url/chat/completions';

      final response = await dio.post(
        apiUrl,
        options: Options(
          headers: getHeaders(),
          validateStatus: (status) => true,
        ),
        data: generateRequestBody(testMessages),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': '连接成功',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'API密钥无效',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'API端点不存在',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': '连接失败 (状态码: ${response.statusCode})',
          'statusCode': response.statusCode,
        };
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {
          'success': false,
          'message': '连接超时',
          'error': e.toString(),
        };
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {
          'success': false,
          'message': '接收超时',
          'error': e.toString(),
        };
      } else if (e.type == DioExceptionType.connectionError) {
        return {
          'success': false,
          'message': '网络连接错误',
          'error': e.toString(),
        };
      } else {
        return {
          'success': false,
          'message': '连接错误: ${e.message}',
          'error': e.toString(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '未知错误: $e',
        'error': e.toString(),
      };
    }
  }
}
