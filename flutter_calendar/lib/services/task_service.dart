import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/services/hive_service.dart';
import 'package:hive/hive.dart';

class TaskService {
  // 单例模式（可选，方便调用）
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  /// 获取所有任务
  List<TaskModel> getAllTasks() {
    return HiveService.getAllTasks();
  }
  
  /// 获取今日任务
  List<TaskModel> getTodayTasks() {
     final DateTime today = DateTime.now();
     return getAllTasks().where((TaskModel t) {
       if (t.dueDate == null) return false;
       return t.dueDate!.year == today.year &&
           t.dueDate!.month == today.month &&
           t.dueDate!.day == today.day;
     }).toList();
  }

  /// 创建任务
  Future<TaskModel> createTask({
    required String title,
    required DateTime dueDate,
    String description = '',
  }) async {
    if (!Hive.isBoxOpen('tasks')) await HiveService.init();

    final TaskModel newTask = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      categoryId: 'default',
    );

    await HiveService.addTask(newTask);
    return newTask;
  }

  /// 更新任务
  Future<void> updateTask(TaskModel task) async {
    await HiveService.updateTask(task);
  }

  /// 删除任务
  Future<void> deleteTask(String taskId) async {
    await HiveService.deleteTask(taskId);
  }
}
