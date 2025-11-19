import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/repositories/task_repository.dart';
import 'package:ai_smart_calendar/services/hive_service.dart';
import 'package:ai_smart_calendar/services/notification_service.dart';
import 'package:ai_smart_calendar/utils/task_notification_scheduler.dart';

class LocalTaskRepository implements TaskRepository {
  LocalTaskRepository();

  // --- 【核心修改】读取方法适配 ---
  // HiveService 的读取方法现在是同步的，但 Repository 接口要求返回 Future。
  // 我们使用 Future.value() 来将同步结果高效地包装成一个已完成的 Future。

  @override
  Future<List<TaskModel>> getTasks() {
    // HiveService.getAllTasks() 直接返回 List<TaskModel>
    return Future.value(HiveService.getAllTasks());
  }

  @override
  Future<TaskModel?> getTaskById(String id) {
    // HiveService.getTask(id) 直接返回 TaskModel?
    return Future.value(HiveService.getTask(id));
  }

  @override
  Future<List<TaskModel>> getTasksByDate(DateTime date) {
    return Future.value(HiveService.getTasksByDate(date));
  }

  @override
  Future<List<TaskModel>> getTasksByCategory(String categoryId) {
    return Future.value(HiveService.getTasksByCategory(categoryId));
  }

  @override
  Future<List<TaskModel>> getCompletedTasks() {
    return Future.value(HiveService.getCompletedTasks());
  }

  @override
  Future<List<TaskModel>> getPendingTasks() {
    return Future.value(HiveService.getPendingTasks());
  }

  @override
  Future<List<TaskModel>> getOverdueTasks() {
    return Future.value(HiveService.getOverdueTasks());
  }

  // --- 写入方法保持不变，因为它们本来就是异步的 ---

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    await HiveService.addTask(task);

    // 创建任务后调度通知
    await TaskNotificationScheduler.scheduleOrCancelTaskNotification(task);

    return task;
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    // 获取旧任务状态以检测完成状态变化
    final TaskModel? oldTask = await getTaskById(task.id);

    await HiveService.updateTask(task);

    // 更新任务后重新调度通知
    await TaskNotificationScheduler.scheduleOrCancelTaskNotification(task);

    // 如果任务从未完成变为完成，显示完成通知
    if (oldTask != null && !oldTask.isCompleted && task.isCompleted) {
      await NotificationService.showTaskCompletedNotification(task);
    }

    return task;
  }

  @override
  Future<void> deleteTask(String id) async {
    // 删除任务前获取任务信息以取消通知
    final TaskModel? task = await getTaskById(id);
    if (task != null) {
      await TaskNotificationScheduler.cancelTaskNotification(task);
    }

    await HiveService.deleteTask(id);
  }

  // --- 其他方法保持不变 ---

  @override
  Future<List<TaskModel>> syncTasks(List<TaskModel> tasks) async {
    // 对于本地仓库，同步意味着在本地保存所有任务
    for (final TaskModel task in tasks) {
      await HiveService.updateTask(task);
    }
    return tasks;
  }

  @override
  Future<List<TaskModel>> getCloudTasks() async {
    // 本地仓库没有云任务，返回空列表
    return <TaskModel>[];
  }
}
