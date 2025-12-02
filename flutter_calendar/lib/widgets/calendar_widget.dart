import 'package:flutter/material.dart';
import 'package:flutter/src/gestures/events.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/theme/app_theme.dart';
import 'package:ai_smart_calendar/providers/tasks_provider.dart';
import 'package:ai_smart_calendar/providers/calendar_providers.dart';

// 一个帮助函数，用于判断两个日期是否是同一天（忽略时间部分）
bool _isSameDay(DateTime? dateA, DateTime? dateB) {
  if (dateA == null || dateB == null) {
    return false;
  }
  return dateA.year == dateB.year &&
      dateA.month == dateB.month &&
      dateA.day == dateB.day;
}

// 修改后的主 Widget
class CalendarWidget extends ConsumerWidget {
  const CalendarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TaskModel>> tasksAsyncValue =
        ref.watch(tasksProvider);

    return Scaffold(
      body: Column(
        children: <Widget>[
          // --- 1. 日历部分 ---
          Expanded(
            flex: 3,
            child: tasksAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object err, StackTrace stack) =>
                  Center(child: Text('加载任务失败: $err')),
              data: (List<TaskModel> tasks) => _CalendarView(tasks: tasks),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // --- 2. 任务列表部分 ---
          const Expanded(
            flex: 2,
            child: _SelectedTasksList(),
          ),
        ],
      ),
    );
  }
}

// 支持鼠标滚轮的日历视图 Widget
class _CalendarView extends ConsumerStatefulWidget {
  final List<TaskModel> tasks;
  const _CalendarView({required this.tasks});

  @override
  ConsumerState<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<_CalendarView> {
  final FocusNode _focusNode = FocusNode();
  DateTime _currentDisplayDate = DateTime.now();
  final CalendarController _calendarController = CalendarController();

  @override
  void initState() {
    super.initState();
    _currentDisplayDate = ref.read(selectedDateProvider);
    _calendarController.displayDate = _currentDisplayDate;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentDisplayDate = DateTime(
        _currentDisplayDate.year,
        _currentDisplayDate.month + delta,
        _currentDisplayDate.day,
      );
      _calendarController.displayDate = _currentDisplayDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateTime selectedDate = ref.watch(selectedDateProvider);

    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _changeMonth(-1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _changeMonth(1);
          }
        }
      },
      child: MouseRegion(
        onEnter: (_) => _focusNode.requestFocus(),
        child: Listener(
          onPointerSignal: (PointerSignalEvent pointerSignal) {
            try {
              final dynamic signal = pointerSignal;
              final dynamic scrollDelta = signal.scrollDelta?.dy;
              if (scrollDelta != null && scrollDelta is double) {
                if (scrollDelta > 0) {
                  _changeMonth(1);
                } else if (scrollDelta < 0) {
                  _changeMonth(-1);
                }
              }
            } catch (e) {
              // 忽略错误
            }
          },
          child: SfCalendar(
            controller: _calendarController,
            initialDisplayDate: _currentDisplayDate,
            initialSelectedDate: selectedDate,
            view: CalendarView.month,
            headerStyle: const CalendarHeaderStyle(textAlign: TextAlign.center),
            dataSource: _getCalendarDataSource(widget.tasks),
            onTap: (CalendarTapDetails details) {
              if (details.targetElement == CalendarElement.calendarCell &&
                  details.date != null) {
                if (!_isSameDay(details.date, selectedDate)) {
                  ref.read(selectedDateProvider.notifier).state = details.date!;
                }
              }
            },
            selectionDecoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: AppTheme.primaryColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            todayHighlightColor: AppTheme.primaryColor,
            cellBorderColor: AppTheme.dividerColor,
          ),
        ),
      ),
    );
  }
}

// 独立的任务列表 Widget
class _SelectedTasksList extends ConsumerWidget {
  const _SelectedTasksList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime selectedDate = ref.watch(selectedDateProvider);
    final AsyncValue<List<TaskModel>> tasksAsyncValue =
        ref.watch(tasksProvider);

    final String dayOfWeek = DateFormat('E', 'zh_CN').format(selectedDate);
    final int dayOfMonth = selectedDate.day;

    return tasksAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object err, StackTrace stack) =>
          Center(child: Text('加载任务失败: $err')),
      data: (List<TaskModel> tasks) {
        final List<TaskModel> selectedTasks = tasks
            .where((TaskModel task) => _isSameDay(task.dueDate, selectedDate))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // [修复]: 进一步减小 Padding (8 -> 4) 并添加 FittedBox
            Container(
              height: 40, // 强制给一个较小的高度约束
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$dayOfWeek $dayOfMonth',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            if (selectedTasks.isEmpty)
              Expanded(
                child: Center(
                  child:
                      Text('今日无任务', style: TextStyle(color: Colors.grey[600])),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(), // 移除列表顶部的额外间距
                  itemCount: selectedTasks.length,
                  itemBuilder: (BuildContext context, int index) {
                    final TaskModel task = selectedTasks[index];
                    return _TaskCard(task: task);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

// 任务卡片 Widget
class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getTaskColor(task),
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (task.dueDate != null && _hasTimeComponent(task.dueDate!))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatTime(task.dueDate!),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            child: Text(
              task.isCompleted ? '已完成' : task.priority.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 辅助函数 ---

_CalendarDataSource _getCalendarDataSource(List<TaskModel> tasks) {
  final List<Appointment> appointments = tasks.map((TaskModel task) {
    return Appointment(
      startTime: task.dueDate ?? task.createdAt,
      endTime: (task.dueDate ?? task.createdAt).add(const Duration(hours: 1)),
      subject: task.title,
      color: _getTaskColor(task),
      isAllDay: true,
      id: task.id,
    );
  }).toList();
  return _CalendarDataSource(appointments);
}

Color _getTaskColor(TaskModel task) {
  if (task.isCompleted) return Colors.grey;
  if (task.isOverdue) return AppTheme.errorColor;

  switch (task.priority) {
    case TaskPriority.urgent:
      return const Color(0xFFFF5252);
    case TaskPriority.high:
      return const Color(0xFFFF9800);
    case TaskPriority.medium:
      return const Color(0xFF2196F3);
    case TaskPriority.low:
      return const Color(0xFF4CAF50);
  }
}

bool _hasTimeComponent(DateTime date) {
  return date.hour != 0 ||
      date.minute != 0 ||
      date.second != 0 ||
      date.millisecond != 0 ||
      date.microsecond != 0;
}

String _formatTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _CalendarDataSource extends CalendarDataSource {
  _CalendarDataSource(List<Appointment> source) {
    appointments = source;
  }
}
