import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/models/category_model.dart';

class ApiService {
  static const String _baseUrl = 'https://api.example.com'; // 替换为实际 API 地址
  static const String _apiKey = 'your_api_key_here'; // 替换为实际 API key

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: <String, dynamic>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
    ),
  );

  // 初始化拦截器
  ApiService() {
    _setupInterceptors();
  }

  // **新增**: 明确的异步初始化方法
  Future<void> init() async {
    // 可以在这里执行需要 await 的操作
    // 比如：从安全存储中读取 token 并设置到 header
    // String? token = await secureStorage.read(key: 'auth_token');
    // _dio.options.headers['Authorization'] = 'Bearer $token';
    // 或者执行一次健康检查
    try {
      await _dio.get('/health').timeout(const Duration(seconds: 5));
      debugPrint('ApiService initialized and server is healthy.');
    } catch (e) {
      debugPrint('ApiService health check failed: $e');
      // 健康检查失败不影响服务继续运行
    }
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          // 添加请求日志
          debugPrint('🚀 Request: ${options.method} ${options.uri}');
          debugPrint('📦 Headers: ${options.headers}');
          if (options.data != null) {
            debugPrint('📝 Body: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          // 添加响应日志
          debugPrint(
            '✅ Response: ${response.statusCode} ${response.statusMessage}',
          );
          debugPrint('📄 Data: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) {
          // 添加错误日志
          debugPrint('❌ Error: ${e.message}');
          debugPrint('📊 Status: ${e.response?.statusCode}');
          debugPrint('📝 Response: ${e.response?.data}');
          return handler.next(e);
        },
      ),
    );
  }

  // AI 相关 API
  Future<String> getAISuggestion(String prompt) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        '/ai/suggest',
        data: <String, Object>{
          'prompt': prompt,
          'context': 'calendar_task_management',
          'max_tokens': 500,
        },
      );

      return (response.data?['suggestion'] as String?) ?? '暂无建议';
    } on DioException catch (e) {
      throw _handleError(e, '获取 AI 建议失败');
    }
  }

  Future<List<String>> getAITaskSuggestions(String context) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        '/ai/task-suggestions',
        data: <String, Object>{
          'context': context,
          'count': 5,
        },
      );

      return List<String>.from(
        (response.data?['suggestions'] as List?) ?? <dynamic>[],
      );
    } on DioException catch (e) {
      throw _handleError(e, '获取任务建议失败');
    }
  }

  Future<Map<String, dynamic>> analyzeTimeUsage(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        '/ai/analyze-time',
        data: <String, String>{
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );

      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _handleError(e, '分析时间使用失败');
    }
  }

  // 任务同步 API
  Future<List<TaskModel>> syncTasks(List<TaskModel> tasks) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        '/tasks/sync',
        data: <String, List<Map<String, dynamic>>>{
          'tasks': tasks.map((TaskModel task) => task.toJson()).toList(),
        },
      );

      return ((response.data?['tasks'] as List?) ?? <dynamic>[])
          .map(
            (taskData) =>
                TaskModel.fromJson(Map<String, dynamic>.from(taskData as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, '同步任务失败');
    }
  }

  Future<List<TaskModel>> getCloudTasks() async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>('/tasks');
      return ((response.data?['tasks'] as List?) ?? <dynamic>[])
          .map(
            (taskData) =>
                TaskModel.fromJson(Map<String, dynamic>.from(taskData as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, '获取云端任务失败');
    }
  }

  Future<TaskModel> createCloudTask(TaskModel task) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        '/tasks',
        data: task.toJson(),
      );

      return TaskModel.fromJson(
        Map<String, dynamic>.from(
          (response.data?['task'] as Map?) ?? <dynamic, dynamic>{},
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e, '创建云端任务失败');
    }
  }

  Future<TaskModel> updateCloudTask(TaskModel task) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.put<Map<String, dynamic>>(
        '/tasks/${task.id}',
        data: task.toJson(),
      );

      return TaskModel.fromJson(
        Map<String, dynamic>.from(
          (response.data?['task'] as Map?) ?? <dynamic, dynamic>{},
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e, '更新云端任务失败');
    }
  }

  Future<void> deleteCloudTask(String taskId) async {
    try {
      await _dio.delete('/tasks/$taskId');
    } on DioException catch (e) {
      throw _handleError(e, '删除云端任务失败');
    }
  }

  // 分类同步 API
  Future<List<CategoryModel>> syncCategories(
    List<CategoryModel> categories,
  ) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        '/categories/sync',
        data: <String, List<Map<String, dynamic>>>{
          'categories': categories
              .map((CategoryModel category) => category.toJson())
              .toList(),
        },
      );

      return ((response.data?['categories'] as List?) ?? <dynamic>[])
          .map(
            (categoryData) => CategoryModel.fromJson(
              Map<String, dynamic>.from(categoryData as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, '同步分类失败');
    }
  }

  Future<List<CategoryModel>> getCloudCategories() async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>('/categories');
      return ((response.data?['categories'] as List?) ?? <dynamic>[])
          .map(
            (categoryData) => CategoryModel.fromJson(
              Map<String, dynamic>.from(categoryData as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, '获取云端分类失败');
    }
  }

  // 用户相关 API
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>('/user/profile');
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _handleError(e, '获取用户信息失败');
    }
  }

  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await _dio.put(
        '/user/preferences',
        data: preferences,
      );
    } on DioException catch (e) {
      throw _handleError(e, '更新用户偏好失败');
    }
  }

  // 数据备份与恢复
  Future<void> backupData(Map<String, dynamic> data) async {
    try {
      await _dio.post<void>(
        '/backup',
        data: data,
      );
    } on DioException catch (e) {
      throw _handleError(e, '数据备份失败');
    }
  }

  Future<Map<String, dynamic>> restoreBackup(String backupId) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>('/backup/$backupId');
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _handleError(e, '恢复备份失败');
    }
  }

  Future<List<Map<String, dynamic>>> getBackupList() async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>('/backup/list');
      return List<Map<String, dynamic>>.from(
        (response.data?['backups'] as List?) ?? <dynamic>[],
      );
    } on DioException catch (e) {
      throw _handleError(e, '获取备份列表失败');
    }
  }

  // 工具方法
  Exception _handleError(DioException e, String defaultMessage) {
    if (e.response != null) {
      final int? statusCode = e.response!.statusCode;
      final errorData = e.response!.data;

      switch (statusCode) {
        case 400:
          return Exception(errorData['message'] ?? '请求参数错误');
        case 401:
          return Exception('认证失败，请重新登录');
        case 403:
          return Exception('权限不足');
        case 404:
          return Exception('资源不存在');
        case 500:
          return Exception('服务器内部错误');
        default:
          return Exception(errorData['message'] ?? defaultMessage);
      }
    } else {
      return Exception(e.message ?? defaultMessage);
    }
  }

  // 网络状态检查
  Future<bool> checkNetworkConnection() async {
    try {
      await _dio.get<void>('/health');
      return true;
    } catch (e) {
      return false;
    }
  }

  // 取消所有请求
  void cancelAllRequests() {
    _dio.close(force: true);
  }

  // 更新认证令牌
  void updateAuthToken(String newToken) {
    _dio.options.headers['Authorization'] = 'Bearer $newToken';
  }

  // 设置超时时间
  void setTimeouts(Duration connectTimeout, Duration receiveTimeout) {
    _dio.options.connectTimeout = connectTimeout;
    _dio.options.receiveTimeout = receiveTimeout;
  }
}
