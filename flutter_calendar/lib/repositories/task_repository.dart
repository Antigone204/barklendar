import 'package:ai_smart_calendar/models/task_model.dart';

abstract class TaskRepository {
  // 获取所有任务
  Future<List<TaskModel>> getTasks();
  
  // 根据ID获取任务
  Future<TaskModel?> getTaskById(String id);
  
  // 创建任务
  Future<TaskModel> createTask(TaskModel task);
  
  // 更新任务
  Future<TaskModel> updateTask(TaskModel task);
  
  // 删除任务
  Future<void> deleteTask(String id);
  
  // 根据日期获取任务
  Future<List<TaskModel>> getTasksByDate(DateTime date);
  
  // 根据分类获取任务
  Future<List<TaskModel>> getTasksByCategory(String categoryId);
  
  // 获取已完成的任务
  Future<List<TaskModel>> getCompletedTasks();
  
  // 获取待处理的任务
  Future<List<TaskModel>> getPendingTasks();
  
  // 获取过期任务
  Future<List<TaskModel>> getOverdueTasks();
  
  // 同步任务（用于云端同步）
  Future<List<TaskModel>> syncTasks(List<TaskModel> tasks);
  
  // 获取云端任务
  Future<List<TaskModel>> getCloudTasks();
}
