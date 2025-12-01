// 1. 【重要】确保导入的是 hive_flutter
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/models/category_model.dart';
import 'package:ai_smart_calendar/services/ai_cache.dart';
import 'package:ai_smart_calendar/utils/app_constants.dart';
import 'package:ai_smart_calendar/providers/tasks_provider.dart';
import 'package:ai_smart_calendar/providers/calendar_providers.dart';
import 'package:ai_smart_calendar/providers/ai_config_provider.dart';

class HiveService {
  static const String _tasksBoxName = 'tasks';
  static const String _categoriesBoxName = 'categories';
  static const String _settingsBoxName = 'settings';

  static Future<void> init() async {
    // 3. 【核心修改】使用 hive_flutter 的专用初始化方法，修复启动崩溃问题
    await Hive.initFlutter();

    // 注册适配器 (这部分代码是正确的，保持不变)
    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(TaskPriorityAdapter());
    Hive.registerAdapter(TaskRecurrenceAdapter());
    Hive.registerAdapter(CategoryModelAdapter());

    // 打开盒子 (这部分代码是正确的，保持不变)
    await Hive.openBox<TaskModel>(_tasksBoxName);
    await Hive.openBox<CategoryModel>(_categoriesBoxName);
    await Hive.openBox<dynamic>(_settingsBoxName);

    // 初始化默认分类 (这部分代码是正确的，保持不变)
    await _initializeDefaultCategories();
  }

  static Future<void> _initializeDefaultCategories() async {
    final Box<CategoryModel> categoriesBox =
        Hive.box<CategoryModel>(_categoriesBoxName);
    if (categoriesBox.isEmpty) {
      for (final CategoryModel category in CategoryModel.defaultCategories) {
        await categoriesBox.put(category.id, category);
      }
    }
  }

  // --- Task 相关操作 ---

  // 写入操作保持异步
  static Future<void> addTask(TaskModel task) async {
    final Box<TaskModel> box = Hive.box<TaskModel>(_tasksBoxName);
    await box.put(task.id, task);
  }

  static Future<void> updateTask(TaskModel task) async {
    final Box<TaskModel> box = Hive.box<TaskModel>(_tasksBoxName);
    await box.put(task.id, task);
  }

  static Future<void> deleteTask(String taskId) async {
    final Box<TaskModel> box = Hive.box<TaskModel>(_tasksBoxName);
    await box.delete(taskId);
  }

  // 4. 【性能优化】读取操作改为同步，移除不必要的 Future
  static TaskModel? getTask(String taskId) {
    final Box<TaskModel> box = Hive.box<TaskModel>(_tasksBoxName);
    return box.get(taskId);
  }

  static List<TaskModel> getAllTasks() {
    final Box<TaskModel> box = Hive.box<TaskModel>(_tasksBoxName);
    return box.values.toList();
  }

  static List<TaskModel> getTasksByCategory(String categoryId) {
    final Box<TaskModel> box = Hive.box<TaskModel>(_tasksBoxName);
    return box.values
        .where((TaskModel task) => task.categoryId == categoryId)
        .toList();
  }

  static List<TaskModel> getTasksByDate(DateTime date) {
    final Box<TaskModel> box = Hive.box<TaskModel>(_tasksBoxName);
    return box.values.where((TaskModel task) {
      final DateTime? taskDate = task.dueDate;
      if (taskDate == null) return false;
      return taskDate.year == date.year &&
          taskDate.month == date.month &&
          taskDate.day == date.day;
    }).toList();
  }

  static List<TaskModel> getCompletedTasks() {
    final Box<TaskModel> box = Hive.box<TaskModel>(_tasksBoxName);
    return box.values.where((TaskModel task) => task.isCompleted).toList();
  }

  static List<TaskModel> getPendingTasks() {
    final Box<TaskModel> box = Hive.box<TaskModel>(_tasksBoxName);
    return box.values.where((TaskModel task) => !task.isCompleted).toList();
  }

  static List<TaskModel> getOverdueTasks() {
    final Box<TaskModel> box = Hive.box<TaskModel>(_tasksBoxName);
    final DateTime now = DateTime.now();
    return box.values
        .where(
          (TaskModel task) =>
              !task.isCompleted &&
              task.dueDate != null &&
              task.dueDate!.isBefore(now),
        )
        .toList();
  }

  // --- Category 相关操作 ---

  static Future<void> addCategory(CategoryModel category) async {
    final Box<CategoryModel> box = Hive.box<CategoryModel>(_categoriesBoxName);
    await box.put(category.id, category);
  }

  static Future<void> updateCategory(CategoryModel category) async {
    final Box<CategoryModel> box = Hive.box<CategoryModel>(_categoriesBoxName);
    await box.put(category.id, category);
  }

  static Future<void> deleteCategory(String categoryId) async {
    final Box<CategoryModel> box = Hive.box<CategoryModel>(_categoriesBoxName);
    await box.delete(categoryId);
  }

  static CategoryModel? getCategory(String categoryId) {
    final Box<CategoryModel> box = Hive.box<CategoryModel>(_categoriesBoxName);
    return box.get(categoryId);
  }

  static List<CategoryModel> getAllCategories() {
    final Box<CategoryModel> box = Hive.box<CategoryModel>(_categoriesBoxName);
    return box.values.toList();
  }

  static List<CategoryModel> getUserCategories() {
    final Box<CategoryModel> box = Hive.box<CategoryModel>(_categoriesBoxName);
    return box.values
        .where((CategoryModel category) => !category.isDefault)
        .toList();
  }

  // --- Settings 相关操作 ---

  static Future<void> saveSetting(String key, dynamic value) async {
    final Box box = Hive.box<dynamic>(_settingsBoxName);
    await box.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    final Box box = Hive.box<dynamic>(_settingsBoxName);
    return box.get(key, defaultValue: defaultValue);
  }

  static Future<void> deleteSetting(String key) async {
    final Box box = Hive.box<dynamic>(_settingsBoxName);
    await box.delete(key);
  }

  // --- 数据统计 (全部改为同步) ---

  static int getTotalTaskCount() {
    final Box<TaskModel> box = Hive.box<TaskModel>(_tasksBoxName);
    return box.length;
  }

  static int getCompletedTaskCount() {
    final Box<TaskModel> box = Hive.box<TaskModel>(_tasksBoxName);
    return box.values.where((TaskModel task) => task.isCompleted).length;
  }

  static int getPendingTaskCount() {
    final Box<TaskModel> box = Hive.box<TaskModel>(_tasksBoxName);
    return box.values.where((TaskModel task) => !task.isCompleted).length;
  }

  static Map<String, int> getTaskCountByCategory() {
    final Box<TaskModel> box = Hive.box<TaskModel>(_tasksBoxName);
    final Map<String, int> result = <String, int>{};

    for (final TaskModel task in box.values) {
      result.update(
        task.categoryId,
        (int count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    return result;
  }

  // --- 数据备份与恢复 (保持异步) ---

  static Future<Map<String, dynamic>> exportData() async {
    final Box<TaskModel> tasksBox = Hive.box<TaskModel>(_tasksBoxName);
    final Box<CategoryModel> categoriesBox =
        Hive.box<CategoryModel>(_categoriesBoxName);
    final Box settingsBox = Hive.box<dynamic>(_settingsBoxName);

    return <String, dynamic>{
      'tasks': tasksBox.values.map((TaskModel task) => task.toJson()).toList(),
      'categories': categoriesBox.values
          .map((CategoryModel category) => category.toJson())
          .toList(),
      'settings': settingsBox.toMap(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  static Future<void> importData(
      Map<String, dynamic> data, WidgetRef ref,) async {
    await clearAllData(ref);

    final Box<TaskModel> tasksBox = Hive.box<TaskModel>(_tasksBoxName);
    final Box<CategoryModel> categoriesBox =
        Hive.box<CategoryModel>(_categoriesBoxName);
    final Box settingsBox = Hive.box<dynamic>(_settingsBoxName);

    if (data['tasks'] is List) {
      for (final taskData in data['tasks'] as List) {
        final TaskModel task =
            TaskModel.fromJson(Map<String, dynamic>.from(taskData as Map));
        await tasksBox.put(task.id, task);
      }
    }
    if (data['categories'] is List) {
      for (final categoryData in data['categories'] as List) {
        final CategoryModel category = CategoryModel.fromJson(
          Map<String, dynamic>.from(categoryData as Map),
        );
        await categoriesBox.put(category.id, category);
      }
    }
    if (data['settings'] is Map) {
      final Map<String, dynamic> settings =
          Map<String, dynamic>.from(data['settings'] as Map);
      for (final MapEntry<String, dynamic> entry in settings.entries) {
        await settingsBox.put(entry.key, entry.value);
      }
    }
  }

  static Future<void> clearAllData(WidgetRef ref) async {
    developer.log('[DataClear] Starting data clearance...',
        name: 'dataclear.debug',);

    final Box<TaskModel> tasksBox = Hive.box<TaskModel>(_tasksBoxName);
    await tasksBox.clear();
    developer.log('[DataClear] Tasks box cleared. Size: ${tasksBox.length}',
        name: 'dataclear.debug',);

    final Box<CategoryModel> categoriesBox =
        Hive.box<CategoryModel>(_categoriesBoxName);
    await categoriesBox.clear();
    developer.log(
        '[DataClear] Categories box cleared. Size: ${categoriesBox.length}',
        name: 'dataclear.debug',);

    final Box settingsBox = Hive.box<dynamic>(_settingsBoxName);
    await settingsBox.clear();
    developer.log(
        '[DataClear] Settings box cleared. Size: ${settingsBox.length}',
        name: 'dataclear.debug',);

    // 关键修复：清除AI配置数据
    await clearAIData(ref);
    developer.log('[DataClear] AI data cleared.', name: 'dataclear.debug');

    await _initializeDefaultCategories();
    developer.log(
        '[DataClear] Data clearance finished. Now invalidating providers...',
        name: 'dataclear.debug',);

    // 关键一步：全局状态重置！
    ref.invalidate(tasksProvider);
    ref.invalidate(selectedDateProvider);
    ref.invalidate(aiConfigProvider);
    // 注意：themeNotifierProvider 不需要失效，因为它不依赖Hive数据

    developer.log('[DataClear] Providers invalidated.',
        name: 'dataclear.debug',);
  }

  /// 清除AI相关数据（配置、提示词、缓存）
  static Future<void> clearAIData(WidgetRef ref) async {
    final Box settingsBox = Hive.box<dynamic>(_settingsBoxName);
    final List allKeys = settingsBox.keys.toList();

    // **优化点**：使用一个Set明确定义所有与新AI配置相关的键
    const Set<String> aiConfigKeysToDelete = <String>{
      'ai_configs', // 新的配置列表键
      'active_ai_config_id', // 新的激活ID键
    };

    final List<String> keysToDelete = <String>[];
    for (final key in allKeys) {
      if (key is String) {
        // 删除所有旧的、分散的配置和提示词键
        if (key.startsWith('ai_config_') || key.startsWith('ai_prompt_')) {
          keysToDelete.add(key);
        }
        // 删除所有新的、集中的配置键
        else if (aiConfigKeysToDelete.contains(key)) {
          keysToDelete.add(key);
        }
      }
    }

    if (keysToDelete.isNotEmpty) {
      await settingsBox.deleteAll(keysToDelete);
      debugPrint(
          'Successfully deleted the following AI keys: $keysToDelete',); // 增加日志
    }

    // 清除AI缓存
    await clearAiCache();

    // 重置选中的AI服务
    await saveSetting('selected_ai_service', 'openai');
  }

  /// 清除所有任务数据
  static Future<void> clearTaskData() async {
    final Box<TaskModel> tasksBox = Hive.box<TaskModel>(_tasksBoxName);
    await tasksBox.clear();
  }

  /// 清除用户自定义分类
  static Future<void> clearUserCategories() async {
    final Box<CategoryModel> categoriesBox =
        Hive.box<CategoryModel>(_categoriesBoxName);

    // 只删除用户自定义的分类，保留默认分类
    final List<CategoryModel> userCategories =
        categoriesBox.values.where((CategoryModel category) => !category.isDefault).toList();

    for (final CategoryModel category in userCategories) {
      await categoriesBox.delete(category.id);
    }
  }

  /// 清除应用设置（保留AI配置）
  static Future<void> clearAppSettings() async {
    final Box settingsBox = Hive.box<dynamic>(_settingsBoxName);

    // 获取所有设置键
    final List allKeys = settingsBox.keys.toList();

    // 删除非AI相关的设置
    for (final key in allKeys) {
      if (key is String) {
        if (!key.startsWith('ai_config_') &&
            !key.startsWith('ai_prompt_') &&
            key != 'selected_ai_service') {
          await settingsBox.delete(key);
        }
      }
    }
  }

  /// 清除缓存数据
  static Future<void> clearCacheData() async {
    await clearAiCache();
  }

  static Future<void> close() async {
    await Hive.close();
  }

  // --- AI 相关配置 ---

  static String get selectedAiService {
    return getSetting('selected_ai_service', defaultValue: 'openai') as String;
  }

  static set selectedAiService(String value) {
    saveSetting('selected_ai_service', value);
  }

  static int get maxAiCacheCount {
    return getSetting('max_ai_cache_count', defaultValue: 100) as int;
  }

  static set maxAiCacheCount(int value) {
    saveSetting('max_ai_cache_count', value);
  }

  static Map<String, String>? getAiConfig(String identifier) {
    final config = getSetting('ai_config_$identifier');
    if (config is Map) {
      return config.cast<String, String>();
    }
    return null;
  }

  static Future<void> saveAiConfig(
      String identifier, Map<String, dynamic> config,) async {
    await saveSetting('ai_config_$identifier', config);
  }

  static Future<void> deleteAiConfig(String identifier) async {
    await deleteSetting('ai_config_$identifier');
  }

  static String getAiPrompt(dynamic promptEnum, {String defaultValue = ''}) {
    final String key = 'ai_prompt_${promptEnum.toString()}';
    return getSetting(key, defaultValue: defaultValue) as String;
  }

  static Future<void> saveAiPrompt(dynamic promptEnum, String prompt) async {
    final String key = 'ai_prompt_${promptEnum.toString()}';
    await saveSetting(key, prompt);
  }

  static Future<void> deleteAiPrompt(dynamic promptEnum) async {
    final String key = 'ai_prompt_${promptEnum.toString()}';
    await deleteSetting(key);
  }

  static Future<void> clearAiCache() async {
    // 清除 AI 缓存逻辑，具体实现可能在其他地方
    // 这里可以调用 AiCache.clearCache() 如果存在
    await AiCache.clearCache();
  }

  // --- 提醒偏移量设置 ---

  static int getDefaultReminderOffset() {
    return getSetting(
      AppConstants.defaultReminderOffset,
      defaultValue: AppConstants.defaultReminderOffsetMinutes,
    ) as int;
  }

  static Future<void> setDefaultReminderOffset(int minutes) async {
    await saveSetting(AppConstants.defaultReminderOffset, minutes);
  }

  // --- AI配置加载方法 (类型安全) ---

  /// 加载AI配置列表
  static Future<List<Map<String, String>>?> loadAiConfigs() async {
    final Box box = Hive.box<dynamic>(_settingsBoxName);
    final data = box.get('ai_configs');

    // 类型安全检查和转换
    if (data is List) {
      // Hive可能存储List<dynamic>，我们需要确保每个元素都是Map<String, String>
      return data
          .map((item) {
            if (item is Map) {
              return Map<String, String>.from(item);
            }
            return <String, String>{}; // 或者其他错误处理
          })
          .where((Map<String, String> map) => map.isNotEmpty)
          .toList();
    }
    return null; // 如果没有数据或类型不匹配，返回null
  }

  /// 加载激活的配置ID
  static Future<String?> loadActiveAiConfigId() async {
    final Box box = Hive.box<dynamic>(_settingsBoxName);
    final data = box.get('active_ai_config_id');

    if (data is String) {
      return data;
    }
    return null;
  }

  /// 保存AI配置列表
  static Future<void> saveAiConfigs(List<Map<String, String>> configs) async {
    await saveSetting('ai_configs', configs);
  }

  /// 保存激活的配置ID
  static Future<void> saveActiveAiConfigId(String activeConfigId) async {
    await saveSetting('active_ai_config_id', activeConfigId);
  }
}
