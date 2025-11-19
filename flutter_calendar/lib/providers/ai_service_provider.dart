import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/providers/ai_config_provider.dart';
import 'package:ai_smart_calendar/services/ai_client.dart';
import 'package:ai_smart_calendar/services/ai_factory.dart';
import 'package:ai_smart_calendar/services/ai_service_interface.dart';
import 'package:ai_smart_calendar/services/openai_client.dart';
import 'package:ai_smart_calendar/services/deepseek_client.dart';
import 'package:ai_smart_calendar/services/generic_openai_compatible_client.dart';

/// AI服务Provider - 监听激活配置变化并自动重建
final aiServiceProvider = Provider<AiClient?>((ref) {
  // 监听激活配置的变化
  final activeConfig = ref.watch(activeAiConfigProvider);

  // 如果没有激活的配置，返回null
  if (activeConfig == null) {
    return null;
  }

  // 核心逻辑：每当 activeConfig 改变，这段代码会重新运行，
  // 从而使用 AiFactory 创建一个全新的、带有最新配置的客户端。
  try {
    // 检查配置中的type字段，如果为'generic'则使用通用客户端
    final type = activeConfig[AiConfigKeys.type];
    if (type == 'generic') {
      return GenericOpenAiCompatibleClient(activeConfig);
    }

    final identifier = activeConfig[AiConfigKeys.type] ?? 'openai';
    switch (identifier) {
      case 'openai':
        return OpenAiClient(activeConfig);
      case 'deepseek':
        return DeepSeekClient(activeConfig);
      case 'generic':
        return GenericOpenAiCompatibleClient(activeConfig);
      default:
        return OpenAiClient(activeConfig); // 默认回退到OpenAI
    }
  } catch (e) {
    // 如果创建客户端失败，返回null
    return null;
  }
});
