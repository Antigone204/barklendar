import 'package:flutter/material.dart';
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/theme/app_theme.dart';

class TodoCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onComplete;

  const TodoCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 完成状态复选框
              _buildCompletionCheckbox(),
              const SizedBox(width: 12),
              // 任务内容
              Expanded(
                child: _buildTaskContent(context),
              ),
              // 优先级指示器
              _buildPriorityIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCheckbox() {
    return Checkbox(
      value: task.isCompleted,
      onChanged: (bool? value) {
        if (onComplete != null) {
          onComplete!(value ?? false);
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildTaskContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 任务标题
        Text(
          task.title,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onSurface,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // 任务描述
        if (task.description.isNotEmpty)
          Text(
            task.description,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 8),
        // 任务元信息
        _buildTaskMeta(context),
      ],
    );
  }

  Widget _buildTaskMeta(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: <Widget>[
        // 截止日期
        if (task.dueDate != null)
          _buildMetaItem(
            context,
            Icons.access_time,
            _formatDueDate(task.dueDate!),
            task.isOverdue
                ? AppTheme.errorColor
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        // 分类
        _buildMetaItem(
          context,
          Icons.category,
          _getCategoryName(task.categoryId),
          Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        // 标签
        ...task.tags.take(2).map((String tag) => _buildTag(context, tag)),
        if (task.tags.length > 2)
          _buildMetaItem(
            context,
            Icons.more_horiz,
            '+${task.tags.length - 2}',
            Theme.of(context).colorScheme.outline,
          ),
      ],
    );
  }

  Widget _buildMetaItem(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildTag(BuildContext context, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: AppTheme.primaryColor,
            ),
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    if (task.isCompleted) {
      // 对于已完成的任务，显示"已完成"文本
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '已完成',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.urgent:
        priorityColor = const Color(0xFFFF5252); // 鲜艳红色 - 紧急优先级
        break;
      case TaskPriority.high:
        priorityColor = const Color(0xFFFF9800); // 橙色 - 高优先级
        break;
      case TaskPriority.medium:
        priorityColor = const Color(0xFF2196F3); // 蓝色 - 中优先级
        break;
      case TaskPriority.low:
        priorityColor = const Color(0xFF4CAF50); // 绿色 - 低优先级
        break;
      default:
        priorityColor = Colors.grey; // 备用颜色
        break;
    }

    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: priorityColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime due = DateTime(dueDate.year, dueDate.month, dueDate.day);

    String dateText;
    if (due == today) {
      dateText = '今天';
    } else if (due == today.add(const Duration(days: 1))) {
      dateText = '明天';
    } else if (due == today.subtract(const Duration(days: 1))) {
      dateText = '昨天';
    } else {
      dateText = '${dueDate.month}月${dueDate.day}日';
    }

    // 添加时间信息（如果设置了具体时间）
    if (dueDate.hour != 0 || dueDate.minute != 0) {
      return '$dateText ${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}';
    } else {
      return dateText;
    }
  }

  String _getCategoryName(String categoryId) {
    // TODO: 从分类服务获取分类名称
    switch (categoryId) {
      case 'work':
        return '工作';
      case 'personal':
        return '个人';
      case 'shopping':
        return '购物';
      case 'health':
        return '健康';
      case 'learning':
        return '学习';
      case 'travel':
        return '旅行';
      default:
        return '其他';
    }
  }
}
