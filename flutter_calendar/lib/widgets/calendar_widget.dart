import 'package:flutter/material.dart';
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
    final tasksAsyncValue = ref.watch(tasksProvider);

    // 注意：如果这个 Widget 已经在一个 Scaffold 内部，您可能需要移除这里的 Scaffold
    return Scaffold(
      body: Column(
        children: [
          // --- 1. 日历部分 ---
          // [MODIFICATION 1]: 使用 Expanded 和 flex 控制视图占比
          Expanded(
            flex: 3, // 日历视图占据 3 份空间
            child: tasksAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('加载任务失败: $err')),
              data: (tasks) => _CalendarView(tasks: tasks),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // --- 2. 任务列表部分 ---
          // [MODIFICATION 1]: 使用 Expanded 和 flex 控制视图占比
          Expanded(
            flex: 2, // 任务列表视图占据 2 份空间
            child: const _SelectedTasksList(),
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
        _currentDisplayDate.day, // 保持当前日期，而不是固定为1号
      );
      // 更新日历控制器的显示日期
      _calendarController.displayDate = _currentDisplayDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);

    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        // 处理键盘事件 - 所有方向键都用于月份切换
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            // 上箭头或左箭头 - 切换到上个月
            _changeMonth(-1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            // 下箭头或右箭头 - 切换到下个月
            _changeMonth(1);
          }
        }
      },
      child: MouseRegion(
        onEnter: (_) => _focusNode.requestFocus(),
        child: Listener(
          onPointerSignal: (pointerSignal) {
            // 处理鼠标滚轮事件
            // 使用反射来访问scrollDelta，避免编译时类型检查
            try {
              final dynamic signal = pointerSignal;
              final dynamic scrollDelta = signal.scrollDelta?.dy;

              if (scrollDelta != null && scrollDelta is double) {
                // 检测滚轮方向
                if (scrollDelta > 0) {
                  // 向下滚动 - 切换到下个月
                  _changeMonth(1);
                } else if (scrollDelta < 0) {
                  // 向上滚动 - 切换到上个月
                  _changeMonth(-1);
                }
              }
            } catch (e) {
              // 忽略错误，继续执行
            }
          },
          child: SfCalendar(
            controller: _calendarController, // 使用控制器来动态控制显示
            initialDisplayDate: _currentDisplayDate,
            initialSelectedDate: selectedDate,
            view: CalendarView.month,
            headerStyle: const CalendarHeaderStyle(textAlign: TextAlign.center),
            dataSource: _getCalendarDataSource(widget.tasks),
            onTap: (details) {
              if (details.targetElement == CalendarElement.calendarCell &&
                  details.date != null) {
                if (!_isSameDay(details.date, selectedDate)) {
                  ref.read(selectedDateProvider.notifier).state = details.date!;
                }
              }
            },
            monthViewSettings: const MonthViewSettings(
              showAgenda: false,
              appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
            ),
            selectionDecoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: AppTheme.primaryColor, width: 2),
              shape: BoxShape.rectangle,
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

// 独立的任务列表 Widget (无改动)
class _SelectedTasksList extends ConsumerWidget {
  const _SelectedTasksList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final tasksAsyncValue = ref.watch(tasksProvider);

    final dayOfWeek = DateFormat('E', 'zh_CN').format(selectedDate);
    final dayOfMonth = selectedDate.day;

    return tasksAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('加载任务失败: $err')),
      data: (tasks) {
        final selectedTasks = tasks
            .where((task) => _isSameDay(task.dueDate, selectedDate))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '$dayOfWeek $dayOfMonth',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
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
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: selectedTasks.length,
                  itemBuilder: (context, index) {
                    final task = selectedTasks[index];
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

// 任务卡片 Widget (添加时间显示)
class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75, // 增加高度以容纳时间显示
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getTaskColor(task),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                width: 1,
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

// [MODIFICATION 2]: 完全重新设计的任务优先级颜色方案
Color _getTaskColor(TaskModel task) {
  // 已完成和已逾期的状态优先显示
  if (task.isCompleted) return Colors.grey; // 灰色 - 已完成任务
  if (task.isOverdue) return AppTheme.errorColor;

  // 根据优先级返回不同颜色 - 全新设计
  switch (task.priority) {
    case TaskPriority.urgent:
      return const Color(0xFFFF5252); // 鲜艳红色 - 紧急优先级
    case TaskPriority.high:
      return const Color(0xFFFF9800); // 橙色 - 高优先级
    case TaskPriority.medium:
      return const Color(0xFF2196F3); // 蓝色 - 中优先级
    case TaskPriority.low:
      return const Color(0xFF4CAF50); // 绿色 - 低优先级
    default:
      return Colors.grey; // 备用颜色
  }
}

// 检查DateTime是否包含时间成分（不只是00:00:00）
bool _hasTimeComponent(DateTime date) {
  return date.hour != 0 ||
      date.minute != 0 ||
      date.second != 0 ||
      date.millisecond != 0 ||
      date.microsecond != 0;
}

// 格式化时间为HH:mm格式
String _formatTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _CalendarDataSource extends CalendarDataSource {
  _CalendarDataSource(List<Appointment> source) {
    appointments = source;
  }
}
