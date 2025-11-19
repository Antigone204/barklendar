import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/repositories/task_repository.dart';
import 'package:ai_smart_calendar/services/api_service.dart';

class ApiTaskRepository implements TaskRepository {
  final ApiService _apiService;

  ApiTaskRepository(this._apiService);

  @override
  Future<List<TaskModel>> getTasks() async {
    return await _apiService.getCloudTasks();
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    final List<TaskModel> tasks = await _apiService.getCloudTasks();
    try {
      return tasks.firstWhere((TaskModel task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    return await _apiService.createCloudTask(task);
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    return await _apiService.updateCloudTask(task);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _apiService.deleteCloudTask(id);
  }

  @override
  Future<List<TaskModel>> getTasksByDate(DateTime date) async {
    final List<TaskModel> tasks = await _apiService.getCloudTasks();
    return tasks.where((TaskModel task) {
      final DateTime taskDate = task.dueDate ?? task.createdAt;
      return taskDate.year == date.year &&
          taskDate.month == date.month &&
          taskDate.day == date.day;
    }).toList();
  }

  @override
  Future<List<TaskModel>> getTasksByCategory(String categoryId) async {
    final List<TaskModel> tasks = await _apiService.getCloudTasks();
    return tasks
        .where((TaskModel task) => task.categoryId == categoryId)
        .toList();
  }

  @override
  Future<List<TaskModel>> getCompletedTasks() async {
    final List<TaskModel> tasks = await _apiService.getCloudTasks();
    return tasks.where((TaskModel task) => task.isCompleted).toList();
  }

  @override
  Future<List<TaskModel>> getPendingTasks() async {
    final List<TaskModel> tasks = await _apiService.getCloudTasks();
    return tasks.where((TaskModel task) => !task.isCompleted).toList();
  }

  @override
  Future<List<TaskModel>> getOverdueTasks() async {
    final List<TaskModel> tasks = await _apiService.getCloudTasks();
    final DateTime now = DateTime.now();
    return tasks
        .where(
          (TaskModel task) =>
              !task.isCompleted &&
              task.dueDate != null &&
              task.dueDate!.isBefore(now),
        )
        .toList();
  }

  @override
  Future<List<TaskModel>> syncTasks(List<TaskModel> tasks) async {
    return await _apiService.syncTasks(tasks);
  }

  @override
  Future<List<TaskModel>> getCloudTasks() async {
    return await _apiService.getCloudTasks();
  }
}
