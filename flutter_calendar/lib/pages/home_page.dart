import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/widgets/todo_card.dart';
import 'package:ai_smart_calendar/widgets/calendar_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_smart_calendar/providers/tasks_provider.dart';
import 'package:ai_smart_calendar/pages/settings_page.dart';
import 'package:ai_smart_calendar/pages/ai_page.dart';
import 'package:ai_smart_calendar/l10n/app_localizations.dart';
import 'package:ai_smart_calendar/providers/ai_config_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    debugPrint('--- HomePage is rebuilding ---');
    final ThemeData theme = Theme.of(context);

    // 将所有页面放入一个列表中
    final List<Widget> pages = <Widget>[
      // 0: 日历视图
      ref.watch(tasksProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stack) => Center(
                child: Text(
                    '${AppLocalizations.of(context)!.loadingFailed}: $error')),
            data: (List<TaskModel> tasks) => const CalendarWidget(),
          ),
      // 1: 任务列表视图
      _buildTaskListView(),
      // 2: AI 助手视图
      const AIPage(),
      // 3: 设置视图
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.aiSmartCalendar),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [],
      ),
      // 使用 IndexedStack 保持所有页面状态
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      floatingActionButton:
          _selectedIndex == 0 ? _buildFloatingActionButton() : null,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTodayTasks() {
    final AsyncValue<List<TaskModel>> todayTasksAsync =
        ref.watch(todayTasksProvider);

    return todayTasksAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) => Container(
        padding: const EdgeInsets.all(16),
        child: Center(
            child:
                Text('${AppLocalizations.of(context)!.loadingFailed}: $error')),
      ),
      data: (List<TaskModel> todayTasks) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Text(
              '${AppLocalizations.of(context)!.todaysTasks} (${todayTasks.length})',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (todayTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.noTasksRest,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.normal),
                  ),
                ),
              )
            else
              Column(
                children: todayTasks
                    .map(
                      (TaskModel task) => TodoCard(
                        task: task,
                        onTap: () {
                          context.push('/task/${task.id}', extra: task);
                        },
                        onComplete: (bool completed) {
                          ref
                              .read(tasksProvider.notifier)
                              .toggleTaskCompletion(task.id, completed);
                        },
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskListView() {
    final AsyncValue<List<TaskModel>> pendingTasksAsync =
        ref.watch(pendingTasksProvider);
    final AsyncValue<List<TaskModel>> completedTasksAsync =
        ref.watch(completedTasksProvider);

    return pendingTasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => Center(
          child:
              Text('${AppLocalizations.of(context)!.loadingFailed}: $error')),
      data: (List<TaskModel> pendingTasks) => completedTasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
            child:
                Text('${AppLocalizations.of(context)!.loadingFailed}: $error')),
        data: (List<TaskModel> completedTasks) => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _buildSectionHeader(AppLocalizations.of(context)!.pendingTasks),
            ...pendingTasks.map(
              (TaskModel task) => TodoCard(
                task: task,
                onTap: () {
                  context.push('/task/${task.id}', extra: task);
                },
                onComplete: (bool completed) {
                  ref
                      .read(tasksProvider.notifier)
                      .toggleTaskCompletion(task.id, completed);
                },
              ),
            ),
            _buildSectionHeader(AppLocalizations.of(context)!.completedTasks),
            ...completedTasks.map(
              (TaskModel task) => TodoCard(
                task: task,
                onTap: () {
                  context.push('/task/${task.id}', extra: task);
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
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_today),
          label: AppLocalizations.of(context)!.calendar,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.list),
          label: AppLocalizations.of(context)!.tasks,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.auto_awesome),
          label: AppLocalizations.of(context)!.ai,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: AppLocalizations.of(context)!.settings,
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    final ThemeData theme = Theme.of(context);
    return FloatingActionButton(
      onPressed: () async {
        final Object? result = await context.push('/add-task');
        if (result != null && result is TaskModel) {
          // 使用 Provider 添加任务
          ref.read(tasksProvider.notifier).addTask(result);
        }
      },
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      child: const Icon(Icons.add),
    );
  }
}
