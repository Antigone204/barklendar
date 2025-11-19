import 'package:ai_smart_calendar/repositories/task_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/providers/repository_providers.dart';
import 'package:ai_smart_calendar/providers/calendar_providers.dart';
import 'package:ai_smart_calendar/utils/date_utils.dart';
import 'package:riverpod/src/async_notifier.dart';

// 1. TasksNotifier 保持不变，它的职责是管理原始的任务列表
class TasksNotifier extends AsyncNotifier<List<TaskModel>> {
  @override
  Future<List<TaskModel>> build() async {
    final TaskRepository repository = ref.read(taskRepositoryProvider);
    // 启动时加载所有任务
    return repository.getTasks();
  }

  // --- 所有业务逻辑方法（addTask, updateTask 等）保持完全不变 ---
  Future<void> addTask(TaskModel task) async {
    final TaskRepository repository = ref.read(taskRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.createTask(task);
      return repository.getTasks();
    });
  }

  Future<void> updateTask(TaskModel task) async {
    final TaskRepository repository = ref.read(taskRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateTask(task);
      return repository.getTasks();
    });
  }

  Future<void> deleteTask(String taskId) async {
    final TaskRepository repository = ref.read(taskRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteTask(taskId);
      return repository.getTasks();
    });
  }

  Future<void> toggleTaskCompletion(String taskId, bool completed) async {
    final TaskRepository repository = ref.read(taskRepositoryProvider);
    // 优化：直接更新，而不是多次读取
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final TaskModel taskToUpdate =
          state.value!.firstWhere((TaskModel t) => t.id == taskId);
      final TaskModel updatedTask = taskToUpdate.copyWith(
        isCompleted: completed,
        completedAt: completed ? DateTime.now() : null,
      );
      await repository.updateTask(updatedTask);
      return repository.getTasks();
    });
  }
}

// 2. 创建一个全局的、唯一的 tasksProvider 实例
final AsyncNotifierProviderImpl<TasksNotifier, List<TaskModel>> tasksProvider =
    AsyncNotifierProvider<TasksNotifier, List<TaskModel>>(
  () {
    return TasksNotifier();
  },
);

// =======================================================================
// 3. 【核心重构】用一个 Provider 替换所有衍生的过滤 Provider
//    这个 Provider 返回的是处理好的 AsyncValue<List<TaskModel>>
// =======================================================================

// A. 定义一个枚举来表示所有可能的过滤类型
enum TaskFilter {
  all, //  যদিও我们没有直接使用，但保留以备将来之需
  tasksForSelectedDate,
  todayTasks,
  pending,
  completed,
}

// B. 创建一个 Provider.family，它可以根据传入的过滤类型来返回不同的结果
final AutoDisposeProviderFamily<AsyncValue<List<TaskModel>>, TaskFilter>
    filteredTasksProvider = Provider.autoDispose
        .family<AsyncValue<List<TaskModel>>, TaskFilter>(
            (AutoDisposeProviderRef<AsyncValue<List<TaskModel>>> ref,
                TaskFilter filter) {
  // 监听（watch）主任务列表的变化
  final AsyncValue<List<TaskModel>> tasksAsync = ref.watch(tasksProvider);

  // 当主列表是加载或错误状态时，直接返回该状态
  if (tasksAsync is! AsyncData<List<TaskModel>>) {
    return tasksAsync;
  }

  // 当主列表有数据时，根据 filter 类型进行过滤
  final List<TaskModel> tasks = tasksAsync.value;

  // 根据传入的 filter 执行不同的逻辑
  switch (filter) {
    case TaskFilter.tasksForSelectedDate:
      final DateTime selectedDate = ref.watch(selectedDateProvider);
      final List<TaskModel> filtered = tasks.where((TaskModel task) {
        if (task.dueDate == null) return false;
        return DateUtils.isSameDay(task.dueDate, selectedDate);
      }).toList();
      return AsyncData(filtered);

    case TaskFilter.todayTasks:
      final DateTime today = DateTime.now();
      final List<TaskModel> filtered = tasks.where((TaskModel task) {
        if (task.dueDate == null) return false;
        return DateUtils.isSameDay(task.dueDate, today);
      }).toList();
      return AsyncData(filtered);

    case TaskFilter.pending:
      final List<TaskModel> filtered =
          tasks.where((TaskModel task) => !task.isCompleted).toList();
      return AsyncData(filtered);

    case TaskFilter.completed:
      final List<TaskModel> filtered =
          tasks.where((TaskModel task) => task.isCompleted).toList();
      return AsyncData(filtered);

    default:
      return AsyncData(tasks);
  }
});

// =======================================================================
// 4. (可选但推荐) 为了方便使用，为最常用的过滤器创建别名
//    这样在 UI 代码中就不需要写 ref.watch(filteredTasksProvider(TaskFilter.todayTasks))
// =======================================================================

final AutoDisposeProvider<AsyncValue<List<TaskModel>>> todayTasksProvider =
    Provider.autoDispose<AsyncValue<List<TaskModel>>>(
  (AutoDisposeProviderRef<AsyncValue<List<TaskModel>>> ref) =>
      ref.watch(filteredTasksProvider(TaskFilter.todayTasks)),
);

final AutoDisposeProvider<AsyncValue<List<TaskModel>>> pendingTasksProvider =
    Provider.autoDispose<AsyncValue<List<TaskModel>>>(
  (AutoDisposeProviderRef<AsyncValue<List<TaskModel>>> ref) =>
      ref.watch(filteredTasksProvider(TaskFilter.pending)),
);

final AutoDisposeProvider<AsyncValue<List<TaskModel>>> completedTasksProvider =
    Provider.autoDispose<AsyncValue<List<TaskModel>>>(
  (AutoDisposeProviderRef<AsyncValue<List<TaskModel>>> ref) =>
      ref.watch(filteredTasksProvider(TaskFilter.completed)),
);

// Provider to get a single task by ID
final AutoDisposeProviderFamily<AsyncValue<TaskModel>, String> taskProvider =
    Provider.autoDispose.family<AsyncValue<TaskModel>, String>(
  (AutoDisposeProviderRef<AsyncValue<TaskModel>> ref, String taskId) {
    final AsyncValue<List<TaskModel>> tasksAsync = ref.watch(tasksProvider);
    return tasksAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (Object error, StackTrace stackTrace) =>
          AsyncValue.error(error, stackTrace),
      data: (List<TaskModel> tasks) {
        TaskModel? task;
        try {
          task = tasks.firstWhere((TaskModel task) => task.id == taskId);
        } catch (e) {
          return AsyncValue.error('Task not found', StackTrace.current);
        }
        return AsyncValue.data(task);
      },
    );
  },
);
