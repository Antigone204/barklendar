import 'dart:async';
import 'dart:convert';
import 'package:ai_smart_calendar/services/ai_client.dart';
import 'package:ai_smart_calendar/services/ai_dio.dart';
import 'package:dio/dio.dart';

/// 通用OpenAI兼容客户端，支持任何遵循OpenAI API规范的AI服务
/// 关键特性：动态配置Base URL，不硬编码特定服务端点
class GenericOpenAiCompatibleClient extends AiClient {
  GenericOpenAiCompatibleClient(super.config);

  @override
  Map<String, String> getHeaders() {
    return <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }

  @override
  String? extractContent(Map<String, dynamic> json) {
    final delta = json['choices'][0]['delta'];
    return delta['content'] as String?;
  }

  @override
  Stream<String> generateStream(List<Map<String, dynamic>> messages) async* {
    final Dio dio = AiDio.instance.dio;

    try {
      // 处理URL路径，确保使用正确的API端点
      final String apiUrl =
          url.endsWith('/chat/completions') ? url : '$url/chat/completions';

      final Response response = await dio.post(
        apiUrl,
        options: Options(
          headers: getHeaders(),
          responseType: ResponseType.stream,
          validateStatus: (int? status) => true,
        ),
        data: generateRequestBody(messages),
      );

      final Stream<List<int>> stream = response.data.stream as Stream<List<int>>;
      await for (final List<int> chunk in stream) {
        if (response.statusCode != 200) {
          yield* Stream.error('Error: ${response.statusCode}');
          continue;
        }

        final List<String> lines = utf8.decode(chunk).split('\n');
        for (final String line in lines) {
          final String? content = await processLine(line);
          if (content != null) {
            yield content;
          }
        }
      }
    } catch (e) {
      yield* Stream.error('Request failed: $e');
    }
  }
}
