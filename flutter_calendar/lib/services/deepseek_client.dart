import 'dart:async';
import 'dart:convert';
import 'package:ai_smart_calendar/services/ai_client.dart';
import 'package:ai_smart_calendar/services/ai_dio.dart';
import 'package:dio/dio.dart';

class DeepSeekClient extends AiClient {
  DeepSeekClient(super.config);

  @override
  Map<String, String> getHeaders() {
    return <String, String>{
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
    final Dio dio = AiDio.instance.dio;

    try {
      // DeepSeek使用与OpenAI兼容的API格式，需要完整的URL路径
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
