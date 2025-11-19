import 'package:ai_smart_calendar/services/ai_client.dart';
import 'package:ai_smart_calendar/services/claude_client.dart';
import 'package:ai_smart_calendar/services/deepseek_client.dart';
import 'package:ai_smart_calendar/services/gemini_client.dart';
import 'package:ai_smart_calendar/services/openai_client.dart';
import 'package:ai_smart_calendar/services/generic_openai_compatible_client.dart';

class AiFactory {
  static Stream<String> generateStream(
    String identifier,
    List<Map<String, dynamic>> messages,
    Map<String, String> config,
  ) {
    // 检查配置中的type字段，如果为'generic'则使用通用客户端
    final type = config[AiConfigKeys.type];
    if (type == 'generic') {
      return genericGenerateStream(messages, config);
    }

    switch (identifier) {
      case "openai":
        return openAiGenerateStream(messages, config);
      case "claude":
        return claudeGenerateStream(messages, config);
      case "gemini":
        return geminiGenerateStream(messages, config);
      case "deepseek":
        return deepSeekGenerateStream(messages, config);
      default:
        throw Exception("Invalid AI identifier: $identifier");
    }
  }
}

Stream<String> openAiGenerateStream(
  List<Map<String, dynamic>> messages,
  Map<String, String> config,
) {
  final client = OpenAiClient(config);
  return client.generateStream(messages);
}

Stream<String> claudeGenerateStream(
  List<Map<String, dynamic>> messages,
  Map<String, String> config,
) {
  final client = ClaudeClient(config);
  return client.generateStream(messages);
}

Stream<String> geminiGenerateStream(
  List<Map<String, dynamic>> messages,
  Map<String, String> config,
) {
  final client = GeminiClient(config);
  return client.generateStream(messages);
}

Stream<String> deepSeekGenerateStream(
  List<Map<String, dynamic>> messages,
  Map<String, String> config,
) {
  final client = DeepSeekClient(config);
  return client.generateStream(messages);
}

Stream<String> genericGenerateStream(
  List<Map<String, dynamic>> messages,
  Map<String, String> config,
) {
  final client = GenericOpenAiCompatibleClient(config);
  return client.generateStream(messages);
}
