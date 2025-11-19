import 'dart:convert';
import 'package:ai_smart_calendar/services/ai_client.dart';
import 'package:ai_smart_calendar/services/ai_dio.dart';
import 'package:dio/dio.dart';

class OpenAiClient extends AiClient {
  OpenAiClient(super.config);

  @override
  Map<String, String> getHeaders() {
    return {
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
    final dio = AiDio.instance.dio;

    try {
      final response = await dio.post(
        url,
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
