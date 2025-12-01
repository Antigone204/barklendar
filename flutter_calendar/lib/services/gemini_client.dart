import 'dart:async';
import 'dart:convert';
import 'package:ai_smart_calendar/services/ai_client.dart';
import 'package:ai_smart_calendar/services/ai_dio.dart';
import 'package:dio/dio.dart';

class GeminiClient extends AiClient {
  GeminiClient(super.config);

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
        throw Exception('Gemini 响应体为空');
      }
      final Stream<List<int>> stream =
          responseBody.stream as Stream<List<int>>;
      final List<int> buffer = <int>[];
      String remainingData = '';

      await for (final List<int> chunk in stream) {
        if (response.statusCode != 200) {
          yield* Stream.error('Error: ${response.statusCode}');
          continue;
        }

        buffer.addAll(chunk);
        try {
          final String decodedData = utf8.decode(buffer);
          buffer.clear();
          final String processData = remainingData + decodedData;
          final List<String> lines = processData.split('\n');
          remainingData = '';

          for (int i = 0; i < lines.length; i++) {
            final String line = lines[i];
            if (line.trim().isEmpty) continue;

            if (i == lines.length - 1 && !line.endsWith(']')) {
              remainingData = line;
              continue;
            }

            if (line.startsWith('data: ')) {
              final String data = line.substring(6);
              if (isDone(data)) break;

              try {
                final Map<String, dynamic> json = jsonDecode(data) as Map<String, dynamic>;
                final String? content = extractContent(json);
                if (content != null) {
                  yield content;
                }
              } catch (e) {
                if (i == lines.length - 1) {
                  remainingData = line;
                  continue;
                }
                yield* Stream.error('Parse error: $e\nData: $data');
                continue;
              }
            }
          }
        } catch (e) {
          if (e is FormatException && e.message.contains('Unfinished UTF-8')) {
            continue;
          }
          yield* Stream.error('Decode error: $e');
        }
      }
    } catch (e) {
      yield* Stream.error('Request failed: $e');
    }
  }
}
