import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/models/category_model.dart';
import 'package:ai_smart_calendar/widgets/ai_button.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_smart_calendar/providers/tasks_provider.dart';
import 'package:ai_smart_calendar/services/hive_service.dart';
import 'package:ai_smart_calendar/l10n/app_localizations.dart';

class TodoDetailPage extends ConsumerStatefulWidget {
  final String? taskId;
  final bool isEditing;

  const TodoDetailPage({
    super.key,
    this.taskId,
    this.isEditing = false,
  });

  @override
  ConsumerState<TodoDetailPage> createState() => _TodoDetailPageState();
}

class _TodoDetailPageState extends ConsumerState<TodoDetailPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _titleFocusNode = FocusNode(); // 标题焦点节点
  final FocusNode _descriptionFocusNode = FocusNode(); // 描述焦点节点
  final FocusNode _tagFocusNode = FocusNode(); // 标签焦点节点
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime? _dueDate;
  late TimeOfDay? _dueTime;
  late TaskPriority _priority;
  late String _categoryId;
  late List<String> _tags;
  late TextEditingController _tagController;
  bool _isSaving = false; // 保存状态标志
  DateTime? _originalCreatedAt; // 原始创建时间（用于编辑时保留）
  bool _hasNotification = true; // 是否启用通知
  int? _reminderOffsetInMinutes; // 提醒偏移量（分钟）

  @override
  void initState() {
    super.initState();

    // 初始化控制器和状态变量
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _dueDate = null;
    _dueTime = null;
    _priority = TaskPriority.medium;
    _categoryId = 'work';
    _tags = [];
    _tagController = TextEditingController();

    // 如果提供了 taskId，从 provider 中获取任务数据
    if (widget.taskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadTaskFromProvider();
        }
      });
    } else {
      // 新建任务时自动聚焦
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _titleFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _titleFocusNode.dispose(); // 销毁标题焦点节点
    _descriptionFocusNode.dispose(); // 销毁描述焦点节点
    _tagFocusNode.dispose(); // 销毁标签焦点节点
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true, // 确保键盘弹出时调整布局
      appBar: AppBar(
        title: Text(widget.isEditing
            ? AppLocalizations.of(context)!.editTask
            : AppLocalizations.of(context)!.newTask),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: <Widget>[
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTask,
            ),
          IconButton(
            icon: _isSaving
                ? const CircularProgressIndicator()
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : () => _saveTask(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 标题
              TextFormField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.taskTitle,
                  border: const OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterTaskTitle;
                  }
                  return null;
                },
                style: Theme.of(context).textTheme.titleMedium,
                autofocus: widget.taskId == null, // 新建任务时自动聚焦
              ),
              const SizedBox(height: 16),
              // 描述
              TextFormField(
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.taskDescription,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              // 截止日期
              _buildDueDateSection(),
              const SizedBox(height: 16),
              // 优先级
              _buildPrioritySection(),
              const SizedBox(height: 16),
              // 分类
              _buildCategorySection(),
              const SizedBox(height: 16),
              // 标签
              _buildTagsSection(),
              const SizedBox(height: 16),
              // 通知设置
              _buildNotificationSection(),
              const SizedBox(height: 24),
              // AI 建议按钮
              _buildAISuggestionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDueDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppLocalizations.of(context)!.dueDateAndTime,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        // 日期选择
        InkWell(
          onTap: _selectDueDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _dueDate != null
                      ? '${_dueDate!.year}年${_dueDate!.month}月${_dueDate!.day}日'
                      : AppLocalizations.of(context)!.selectDate,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: _dueDate != null
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.outline,
                      ),
                ),
                const Spacer(),
                if (_dueDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _dueDate = null;
                        _dueTime = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 时间选择
        InkWell(
          onTap: _selectDueTime,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.access_time,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _dueTime != null
                      ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
                      : AppLocalizations.of(context)!.selectTime,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: _dueTime != null
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppLocalizations.of(context)!.priority,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TaskPriority.values.map((TaskPriority priority) {
            return ChoiceChip(
              label: Text(priority.displayName),
              selected: _priority == priority,
              onSelected: (bool selected) {
                setState(() {
                  _priority = priority;
                });
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: _priority == priority
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    final List<CategoryModel> categories = CategoryModel.defaultCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppLocalizations.of(context)!.category,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((CategoryModel category) {
            return FilterChip(
              label: Text(category.name),
              selected: _categoryId == category.id,
              onSelected: (bool selected) {
                setState(() {
                  _categoryId = category.id;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: category.materialColor.withOpacity(0.2),
              checkmarkColor: category.materialColor,
              labelStyle: TextStyle(
                color: _categoryId == category.id
                    ? category.materialColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
              avatar: Icon(
                category.iconData,
                size: 16,
                color: _categoryId == category.id
                    ? category.materialColor
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppLocalizations.of(context)!.tags,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        // 标签输入
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.enterTagsHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addTag,
                  ),
                ),
                onFieldSubmitted: (String value) {
                  _addTag();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 标签显示
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _tags.map((String tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () {
                  setState(() {
                    _tags.remove(tag);
                  });
                },
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
                deleteIcon: Icon(
                  Icons.close,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    // 定义提醒偏移量选项
    final List<Map<String, dynamic>> reminderOptions = [
      {'label': '准时提醒', 'minutes': 0},
      {'label': '提前5分钟', 'minutes': 5},
      {'label': '提前15分钟', 'minutes': 15},
      {'label': '提前30分钟', 'minutes': 30},
      {'label': '提前1小时', 'minutes': 60},
      {'label': '提前2小时', 'minutes': 120},
      {'label': '提前1天', 'minutes': 1440},
    ];

    // 如果没有设置偏移量，使用全局默认值
    final int currentOffset =
        _reminderOffsetInMinutes ?? HiveService.getDefaultReminderOffset();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppLocalizations.of(context)!.notificationSettings,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        // 启用通知开关
        Row(
          children: <Widget>[
            Switch(
              value: _hasNotification,
              onChanged: (bool value) {
                setState(() {
                  _hasNotification = value;
                });
              },
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.enableTaskReminders,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 提醒时间下拉菜单
        if (_hasNotification)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppLocalizations.of(context)!.earlyTime,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  value: currentOffset,
                  isExpanded: true,
                  items: reminderOptions.map((option) {
                    return DropdownMenuItem<int>(
                      value: option['minutes'] as int,
                      child: Text(option['label'] as String),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _reminderOffsetInMinutes = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAISuggestionButton() {
    return AIButton(
      onPressed: _getAISuggestions,
      text: AppLocalizations.of(context)!.getAISuggestions,
    );
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectDueTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  void _addTag() {
    final String tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  // 从 provider 中加载任务数据
  void _loadTaskFromProvider() {
    try {
      final tasks = ref.read(tasksProvider).value;
      if (tasks != null && widget.taskId != null) {
        debugPrint('正在加载任务 ID: ${widget.taskId}');
        debugPrint('可用任务数量: ${tasks.length}');

        final task = tasks.firstWhere(
          (t) => t.id == widget.taskId,
          orElse: () => throw Exception('未找到 ID 为 ${widget.taskId} 的任务'),
        );

        debugPrint('找到任务: ${task.title}');

        setState(() {
          _titleController.text = task.title;
          _descriptionController.text = task.description;
          _dueDate = task.dueDate;
          _dueTime = task.dueDate != null
              ? TimeOfDay.fromDateTime(task.dueDate!)
              : null;
          _priority = task.priority;
          _categoryId = task.categoryId;
          _tags = List.from(task.tags);
          _originalCreatedAt = task.createdAt; // 保存原始创建时间
          _hasNotification = task.hasNotification;
          _reminderOffsetInMinutes = task.reminderOffsetInMinutes;
        });
      } else {
        debugPrint('任务数据为空或 taskId 为 null');
      }
    } catch (e) {
      debugPrint('加载任务失败: $e');
      // 显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载任务失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // 返回上一页
      if (mounted) {
        context.pop();
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      // 表单验证失败，显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseFillRequiredFields),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 检查日期是否填写（日期为必填项）
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectDate),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // 合并日期和时间
    DateTime? finalDueDate;
    if (_dueDate != null && _dueTime != null) {
      finalDueDate = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime!.hour,
        _dueTime!.minute,
      );
    } else if (_dueDate != null) {
      finalDueDate = _dueDate; // 只有日期，没有时间
    }

    final TaskModel task = TaskModel(
      id: widget.taskId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      createdAt: _originalCreatedAt ?? DateTime.now(),
      dueDate: finalDueDate,
      priority: _priority,
      categoryId: _categoryId,
      tags: _tags,
      hasNotification: _hasNotification,
      reminderOffsetInMinutes: _reminderOffsetInMinutes,
    );

    try {
      if (widget.isEditing) {
        await ref.read(tasksProvider.notifier).updateTask(task);
      } else {
        await ref.read(tasksProvider.notifier).addTask(task);
      }

      // 保存成功后返回任务对象
      if (mounted) {
        context.pop(task);
      }
    } catch (e) {
      // 处理保存错误
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _deleteTask() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDelete),
        content: Text(AppLocalizations.of(context)!.deleteTaskConfirmation),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(tasksProvider.notifier)
                    .deleteTask(widget.taskId!);
                if (mounted) {
                  context.pop();
                  context.pop(true); // 返回删除成功标志
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${AppLocalizations.of(context)!.deleteFailed}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  context.pop(); // 关闭确认对话框
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _getAISuggestions() {
    // TODO: 实现 AI 建议功能
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.aiSuggestions),
        content: Text(AppLocalizations.of(context)!.aiSuggestionsInDevelopment),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.pop(),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }
}
