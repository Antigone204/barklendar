import 'dart:async';
import 'dart:convert';
import 'package:ai_smart_calendar/services/ai_client.dart';
import 'package:ai_smart_calendar/services/ai_dio.dart';
import 'package:dio/dio.dart';

class GeminiClient extends AiClient {
  GeminiClient(super.config);

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
      List<int> buffer = [];
      String remainingData = '';

      await for (final chunk in stream) {
        if (response.statusCode != 200) {
          yield* Stream.error('Error: ${response.statusCode}');
          continue;
        }

        buffer.addAll(chunk);
        try {
          final String decodedData = utf8.decode(buffer);
          buffer.clear();
          final String processData = remainingData + decodedData;
          final lines = processData.split('\n');
          remainingData = '';

          for (int i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.trim().isEmpty) continue;

            if (i == lines.length - 1 && !line.endsWith(']')) {
              remainingData = line;
              continue;
            }

            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (isDone(data)) break;

              try {
                final json = jsonDecode(data) as Map<String, dynamic>;
                final content = extractContent(json);
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
