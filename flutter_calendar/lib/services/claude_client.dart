import 'dart:async';
import 'dart:convert';
import 'package:ai_smart_calendar/services/ai_client.dart';
import 'package:ai_smart_calendar/services/ai_dio.dart';
import 'package:dio/dio.dart';

class ClaudeClient extends AiClient {
  ClaudeClient(super.config);

  @override
  Map<String, String> getHeaders() {
    return <String, String>{
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    };
  }

  @override
  String? extractContent(Map<String, dynamic> json) {
    if (json['type'] == 'content_block_delta') {
      return json['delta']['text'] as String?;
    }
    return null;
  }

  @override
  bool isDone(String data) {
    return false;
  }

  @override
  FutureOr<String?> processLine(String line) async {
    if (line.isEmpty || line.startsWith('event: ')) return null;

    final String data = line.startsWith('data: ') ? line.substring(6) : line;
    try {
      final Map<String, dynamic> json = jsonDecode(data) as Map<String, dynamic>;
      return extractContent(json);
    } catch (e) {
      throw Exception('Parse error: $e\nData: $data');
    }
  }

  @override
  Stream<String> generateStream(List<Map<String, dynamic>> messages) async* {
    final Dio dio = AiDio.instance.dio;

    try {
      final Response response = await dio.post(
        url,
        options: Options(
          headers: getHeaders(),
          responseType: ResponseType.stream,
          validateStatus: (int? status) => true,
        ),
        data: <String, Object>{
          'model': model,
          'messages': messages,
          'stream': true,
        },
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
