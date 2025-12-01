import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/widgets/todo_card.dart';
import 'package:ai_smart_calendar/providers/tasks_provider.dart';
import 'package:ai_smart_calendar/l10n/app_localizations.dart';
import 'package:ai_smart_calendar/utils/route_utils.dart';

class TaskListPage extends ConsumerWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用组合 provider，一次性获取 pending 和 completed 任务
    final AsyncValue<TaskListState> taskListState =
        ref.watch(taskListStateProvider);

    return taskListState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => Center(
        child: Text('${AppLocalizations.of(context)!.loadingFailed}: $error'),
      ),
      data: (TaskListState state) => ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // 待办任务部分
          _buildSectionHeader(
              context, AppLocalizations.of(context)!.pendingTasks,),
          ...state.pending.map(
            (TaskModel task) => TodoCard(
              task: task,
              onTap: () {
                context.toTaskDetail(task: task);
              },
              onComplete: (bool completed) {
                ref
                    .read(tasksProvider.notifier)
                    .toggleTaskCompletion(task.id, completed);
              },
            ),
          ),
          // 已完成任务部分
          _buildSectionHeader(
              context, AppLocalizations.of(context)!.completedTasks,),
          ...state.completed.map(
            (TaskModel task) => TodoCard(
              task: task,
              onTap: () {
                context.toTaskDetail(task: task);
              },
              onComplete: (bool completed) {
                ref
                    .read(tasksProvider.notifier)
                    .toggleTaskCompletion(task.id, completed);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

