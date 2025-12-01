import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/repositories/task_repository.dart';
import 'package:ai_smart_calendar/repositories/impl/api_task_repository.dart';
import 'package:ai_smart_calendar/repositories/impl/local_task_repository.dart';
import 'package:ai_smart_calendar/services/api_service.dart';
import 'package:ai_smart_calendar/services/calendar_tool_service.dart';
import 'package:ai_smart_calendar/services/tool_registry_service.dart';
import 'package:ai_smart_calendar/services/tool_calling_service.dart';
import 'package:ai_smart_calendar/services/ai_service_instance.dart';
import 'package:ai_smart_calendar/services/ai_service_interface.dart';
import 'package:ai_smart_calendar/services/unconfigured_ai_service.dart';
import 'package:ai_smart_calendar/providers/ai_config_provider.dart';

// API Service Provider
final Provider<ApiService> apiServiceProvider =
    Provider<ApiService>((ProviderRef<ApiService> ref) => ApiService());

// Task Repository Provider - defaults to local repository
final Provider<TaskRepository> taskRepositoryProvider =
    Provider<TaskRepository>((ProviderRef<TaskRepository> ref) {
  // For now, we'll use local repository by default
  // In a real app, you might check network connectivity here
  // and return ApiTaskRepository when online
  return LocalTaskRepository();
});

// Optional: Separate providers for different repository types
final Provider<TaskRepository> localTaskRepositoryProvider =
    Provider<TaskRepository>((ProviderRef<TaskRepository> ref) {
  return LocalTaskRepository();
});

final Provider<TaskRepository> apiTaskRepositoryProvider =
    Provider<TaskRepository>((ProviderRef<TaskRepository> ref) {
  final ApiService apiService = ref.read(apiServiceProvider);
  return ApiTaskRepository(apiService);
});

// Calendar Tool Service Provider
final Provider<CalendarToolService> calendarToolServiceProvider =
    Provider<CalendarToolService>((ProviderRef<CalendarToolService> ref) {
  final TaskRepository taskRepository = ref.read(taskRepositoryProvider);
  return CalendarToolService(taskRepository, ref);
});

// Tool Registry Service Provider
final Provider<ToolRegistryService> toolRegistryServiceProvider =
    Provider<ToolRegistryService>((ProviderRef<ToolRegistryService> ref) {
  final ToolRegistryService registry = ToolRegistryService();

  // 注册所有可用工具
  registry.registerTool(CalendarToolService.toolDefinition);

  // 未来添加新工具时，只需在这里添加一行：
  // registry.registerTool(WeatherToolService.toolDefinition);
  // registry.registerTool(EmailToolService.toolDefinition);

  return registry;
});

// AI Service Provider (实例化版本)
final Provider<AIService> aiServiceProvider = Provider<AIService>((ProviderRef<AIService> ref) {
  // 关键：使用 ref.watch() 来监听 activeAiConfigProvider 的状态！
  final Map<String, String>? activeConfig = ref.watch(activeAiConfigProvider);

  // ======================= 📍 探针 2 =======================
  developer.log(
      '[PROBE LOG] aiServiceProvider is being REBUILT. Active config ID from configProvider: ${activeConfig?['id']}',
      name: 'probe.debug',);
  // ========================================================

  // 安全检查：如果没有任何激活的配置，我们返回一个"哑"服务
  if (activeConfig == null || activeConfig['url']?.isEmpty == true) {
    return UnconfiguredAIService();
  }

  // 如果配置有效，我们就用它来创建一个新的、配置正确的服务实例！
  return AIServiceInstance(config: activeConfig);
});

// Tool Calling Service Provider
final Provider<ToolCallingService> toolCallingServiceProvider =
    Provider<ToolCallingService>((ProviderRef<ToolCallingService> ref) {
  // ======================= 📍 探针 3 =======================
  developer.log('[PROBE LOG] toolCallingServiceProvider is being CREATED.',
      name: 'probe.debug',);
  // ========================================================

  final ToolRegistryService toolRegistry =
      ref.read(toolRegistryServiceProvider);
  final CalendarToolService calendarToolService =
      ref.read(calendarToolServiceProvider);

  return ToolCallingService(
    ref: ref,
    toolRegistry: toolRegistry,
    calendarToolService: calendarToolService,
  );
});
