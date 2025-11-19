import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/services/hive_service.dart';
import 'package:ai_smart_calendar/services/ai_client.dart';

/// AI配置状态类
class AiConfigState {
  final List<Map<String, String>> configs;
  final String activeConfigId;

  AiConfigState({required this.configs, required this.activeConfigId});

  AiConfigState copyWith({
    List<Map<String, String>>? configs,
    String? activeConfigId,
  }) {
    return AiConfigState(
      configs: configs ?? this.configs,
      activeConfigId: activeConfigId ?? this.activeConfigId,
    );
  }

  /// 创建默认状态
  static AiConfigState defaultState() {
    final defaultConfigs = [
      {
        'id': 'openai',
        'name': 'OpenAI',
        AiConfigKeys.type: 'openai',
        AiConfigKeys.url: 'https://api.openai.com/v1',
        AiConfigKeys.apiKey: '',
        AiConfigKeys.model: 'gpt-3.5-turbo',
      },
      {
        'id': 'deepseek',
        'name': 'DeepSeek',
        AiConfigKeys.type: 'deepseek',
        AiConfigKeys.url: 'https://api.deepseek.com/v1',
        AiConfigKeys.apiKey: '',
        AiConfigKeys.model: 'deepseek-chat',
      },
      {
        'id': 'generic',
        'name': '通用服务',
        AiConfigKeys.type: 'generic',
        AiConfigKeys.url: '',
        AiConfigKeys.apiKey: '',
        AiConfigKeys.model: '',
      },
    ];
    return AiConfigState(
      configs: defaultConfigs,
      activeConfigId: defaultConfigs.first['id']!,
    );
  }
}

/// AI配置状态管理AsyncNotifier
class AiConfigNotifier extends AsyncNotifier<AiConfigState> {
  @override
  Future<AiConfigState> build() async {
    // 添加日志，追踪加载过程的开始
    debugPrint('[AIConfigProvider] Build method started. Loading from Hive...');

    try {
      // 1. 并行加载所有需要的数据
      final results = await Future.wait([
        HiveService.loadAiConfigs(),
        HiveService.loadActiveAiConfigId(),
      ]);

      // 2. 解析加载结果
      final loadedConfigs = results[0] as List<Map<String, String>>?;
      final activeConfigId = results[1] as String?;

      // 3. **核心逻辑：检查加载的数据是否有效**
      if (loadedConfigs != null && loadedConfigs.isNotEmpty) {
        // 如果成功加载了配置列表
        debugPrint(
            '[AIConfigProvider] Successfully loaded ${loadedConfigs.length} configs from Hive.');

        // 验证 activeConfigId 是否仍然有效，如果无效则回退到第一个
        final validActiveId = activeConfigId != null &&
                loadedConfigs.any((c) => c['id'] == activeConfigId)
            ? activeConfigId
            : loadedConfigs.first['id'];

        debugPrint(
            '[AIConfigProvider] Active config ID set to: $validActiveId');

        return AiConfigState(
          configs: loadedConfigs,
          activeConfigId: validActiveId!,
        );
      } else {
        // 4. **回退逻辑：如果Hive中没有数据，则创建并返回默认配置**
        debugPrint(
            '[AIConfigProvider] No configs found in Hive. Creating default config...');
        final defaultState = AiConfigState.defaultState();

        // **重要**：将创建的默认配置立即存入Hive，以便下次能加载
        await HiveService.saveAiConfigs(defaultState.configs);
        await HiveService.saveActiveAiConfigId(defaultState.activeConfigId);
        debugPrint(
            '[AIConfigProvider] Default config saved to Hive for future use.');

        return defaultState;
      }
    } catch (e, stackTrace) {
      debugPrint(
          '[AIConfigProvider] Error loading from Hive. Falling back to default. Error: $e');
      // 如果加载过程中发生任何错误，也安全地回退到默认状态
      return AiConfigState.defaultState();
    }
  }

  /// 保存配置到Hive
  Future<void> _saveConfigs(AiConfigState state) async {
    await HiveService.saveAiConfigs(state.configs);
    await HiveService.saveActiveAiConfigId(state.activeConfigId);
    debugPrint(
        'AI配置已保存到Hive: ${state.configs.length} 个配置，激活配置ID: ${state.activeConfigId}'); // 增加日志
  }

  /// 添加新配置
  Future<void> addConfig(Map<String, String> newConfig) async {
    // 先更新状态，再持久化
    final previousState = await future;
    final configs = List<Map<String, String>>.from(previousState.configs);

    // 确保配置有ID
    if (!newConfig.containsKey('id') || newConfig['id']!.isEmpty) {
      newConfig['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    }

    configs.add(newConfig);
    final newState = previousState.copyWith(configs: configs);
    state = AsyncData(newState); // 关键：立即更新UI
    await _saveConfigs(newState);
  }

  /// 更新配置
  Future<void> updateConfig(
      String id, Map<String, String> updatedConfig) async {
    final previousState = await future;
    final configs = List<Map<String, String>>.from(previousState.configs);
    final index = configs.indexWhere((config) => config['id'] == id);

    if (index != -1) {
      configs[index] = updatedConfig;
      final newState = previousState.copyWith(configs: configs);
      state = AsyncData(newState);
      await _saveConfigs(newState);
    }
  }

  /// 删除配置
  Future<void> deleteConfig(String id) async {
    final previousState = await future;
    final configs = List<Map<String, String>>.from(previousState.configs);
    configs.removeWhere((config) => config['id'] == id);

    // 如果删除的是当前激活的配置，则激活第一个配置
    String activeConfigId = previousState.activeConfigId;
    if (activeConfigId == id && configs.isNotEmpty) {
      activeConfigId = configs.first['id']!;
    }

    final newState = previousState.copyWith(
      configs: configs,
      activeConfigId: activeConfigId,
    );
    state = AsyncData(newState);
    await _saveConfigs(newState);
  }

  /// 设置激活配置
  Future<void> setActiveConfig(String id) async {
    final previousState = await future;
    final config = previousState.configs.firstWhere(
      (config) => config['id'] == id,
      orElse: () => previousState.configs.first,
    );

    final newState = previousState.copyWith(activeConfigId: config['id']!);
    state = AsyncData(newState);
    await _saveConfigs(newState);

    // 同时更新HiveService中的selectedAiService
    HiveService.selectedAiService = config[AiConfigKeys.type] ?? 'openai';
  }

  /// 获取当前激活的配置
  Map<String, String>? getActiveConfig() {
    final currentState = state.value;
    if (currentState == null) return null;

    return currentState.configs.firstWhere(
      (config) => config['id'] == currentState.activeConfigId,
      orElse: () =>
          currentState.configs.isNotEmpty ? currentState.configs.first : {},
    );
  }

  /// 根据ID获取配置
  Map<String, String>? getConfigById(String id) {
    final currentState = state.value;
    if (currentState == null) return null;

    return currentState.configs.firstWhere(
      (config) => config['id'] == id,
      orElse: () => {},
    );
  }
}

/// AI配置状态Provider
final aiConfigProvider = AsyncNotifierProvider<AiConfigNotifier, AiConfigState>(
  () => AiConfigNotifier(),
);

/// 当前激活配置的Provider
final activeAiConfigProvider = Provider<Map<String, String>?>((ref) {
  final asyncState = ref.watch(aiConfigProvider);

  return asyncState.when(
    data: (state) {
      return state.configs.firstWhere(
        (config) => config['id'] == state.activeConfigId,
        orElse: () => state.configs.isNotEmpty ? state.configs.first : {},
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// AI配置列表Provider
final aiConfigsProvider = Provider<List<Map<String, String>>>((ref) {
  final asyncState = ref.watch(aiConfigProvider);

  return asyncState.when(
    data: (state) => state.configs,
    loading: () => [],
    error: (_, __) => [],
  );
});
