import 'dart:async';
import 'dart:convert';
import 'package:ai_smart_calendar/services/ai_client.dart';
import 'package:ai_smart_calendar/services/ai_dio.dart';
import 'package:dio/dio.dart';

class DeepSeekClient extends AiClient {
  DeepSeekClient(super.config);

  @override
  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }

  @override
  String? extractContent(Map<String, dynamic> json) {
    String? content = json['choices'][0]['delta']['content'] as String?;
    content ??= json['choices'][0]['delta']['reasoning_content'] as String?;
    return content;
  }

  @override
  Stream<String> generateStream(List<Map<String, dynamic>> messages) async* {
    final dio = AiDio.instance.dio;

    try {
      // DeepSeek使用与OpenAI兼容的API格式，需要完整的URL路径
      final apiUrl =
          url.endsWith('/chat/completions') ? url : '$url/chat/completions';

      final response = await dio.post(
        apiUrl,
        options: Options(
          headers: getHeaders(),
          responseType: ResponseType.stream,
          validateStatus: (status) => true,
        ),
        data: generateRequestBody(messages),
      );

      final stream = response.data.stream as Stream<List<int>>;
      await for (final chunk in stream) {
        if (response.statusCode != 200) {
          yield* Stream.error('Error: ${response.statusCode}');
          continue;
        }

        final lines = utf8.decode(chunk).split('\n');
        for (final line in lines) {
          final content = await processLine(line);
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
