import 'dart:convert';
import 'package:ai_smart_calendar/services/ai_client.dart';
import 'package:ai_smart_calendar/services/ai_dio.dart';
import 'package:dio/dio.dart';

class OpenAiClient extends AiClient {
  OpenAiClient(super.config);

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
      final Response<ResponseBody> response =
          await dio.post<ResponseBody>(
        url,
        options: Options(
          headers: getHeaders(),
          responseType: ResponseType.stream,
          validateStatus: (int? status) => true,
        ),
        data: generateRequestBody(messages),
      );

      final ResponseBody? responseBody = response.data;
      if (responseBody == null) {
        throw Exception('OpenAI 响应体为空');
      }
      final Stream<List<int>> stream =
          responseBody.stream as Stream<List<int>>;
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
