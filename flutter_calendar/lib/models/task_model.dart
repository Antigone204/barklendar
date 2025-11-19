import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime? dueDate;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  TaskPriority priority;

  @HiveField(7)
  String categoryId;

  @HiveField(8)
  List<String> tags;

  @HiveField(9)
  DateTime? reminderTime;

  @HiveField(10)
  bool hasNotification;

  @HiveField(11)
  String? location;

  @HiveField(12)
  TaskRecurrence? recurrence;

  @HiveField(13)
  DateTime? completedAt;

  @HiveField(14)
  String? aiGeneratedSuggestion;

  @HiveField(15)
  int? reminderOffsetInMinutes;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    this.dueDate,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    required this.categoryId,
    this.tags = const <String>[],
    this.reminderTime,
    this.hasNotification = false,
    this.location,
    this.recurrence,
    this.completedAt,
    this.aiGeneratedSuggestion,
    this.reminderOffsetInMinutes,
  });

  // 工厂构造函数：从 JSON 创建
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: TaskPriority.values.firstWhere(
        (TaskPriority e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      categoryId: json['categoryId'] as String,
      tags: List<String>.from(json['tags'] as List? ?? <dynamic>[]),
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'] as String)
          : null,
      hasNotification: json['hasNotification'] as bool? ?? false,
      location: json['location'] as String?,
      recurrence: json['recurrence'] != null
          ? TaskRecurrence.values.firstWhere(
              (TaskRecurrence e) => e.name == json['recurrence'],
              orElse: () => TaskRecurrence.none,
            )
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      aiGeneratedSuggestion: json['aiGeneratedSuggestion'] as String?,
      reminderOffsetInMinutes: json['reminderOffsetInMinutes'] as int?,
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'priority': priority.name,
      'categoryId': categoryId,
      'tags': tags,
      'reminderTime': reminderTime?.toIso8601String(),
      'hasNotification': hasNotification,
      'location': location,
      'recurrence': recurrence?.name,
      'completedAt': completedAt?.toIso8601String(),
      'aiGeneratedSuggestion': aiGeneratedSuggestion,
      'reminderOffsetInMinutes': reminderOffsetInMinutes,
    };
  }

  // 复制任务并修改某些字段
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isCompleted,
    TaskPriority? priority,
    String? categoryId,
    List<String>? tags,
    DateTime? reminderTime,
    bool? hasNotification,
    String? location,
    TaskRecurrence? recurrence,
    DateTime? completedAt,
    String? aiGeneratedSuggestion,
    int? reminderOffsetInMinutes,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      reminderTime: reminderTime ?? this.reminderTime,
      hasNotification: hasNotification ?? this.hasNotification,
      location: location ?? this.location,
      recurrence: recurrence ?? this.recurrence,
      completedAt: completedAt ?? this.completedAt,
      aiGeneratedSuggestion:
          aiGeneratedSuggestion ?? this.aiGeneratedSuggestion,
      reminderOffsetInMinutes:
          reminderOffsetInMinutes ?? this.reminderOffsetInMinutes,
    );
  }

  // 检查任务是否过期 - 只比较日期部分，忽略时间
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime dueDay =
        DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return today.isAfter(dueDay);
  }

  // 检查任务是否是今天的
  bool get isToday {
    if (dueDate == null) return false;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime taskDate =
        DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return today == taskDate;
  }

  // 检查任务是否是本周的
  bool get isThisWeek {
    if (dueDate == null) return false;
    final DateTime now = DateTime.now();
    final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    return dueDate!.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        dueDate!.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // 获取任务状态文本
  String get statusText {
    if (isCompleted) return '已完成';
    if (isOverdue) return '已过期';
    if (isToday) return '今天';
    return '待完成';
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, isCompleted: $isCompleted, dueDate: $dueDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 1)
enum TaskPriority {
  @HiveField(0)
  low('低', 1),

  @HiveField(1)
  medium('中', 2),

  @HiveField(2)
  high('高', 3),

  @HiveField(3)
  urgent('紧急', 4);

  const TaskPriority(this.displayName, this.value);

  final String displayName;
  final int value;
}

@HiveType(typeId: 2)
enum TaskRecurrence {
  @HiveField(0)
  none('不重复'),

  @HiveField(1)
  daily('每天'),

  @HiveField(2)
  weekly('每周'),

  @HiveField(3)
  monthly('每月'),

  @HiveField(4)
  yearly('每年');

  const TaskRecurrence(this.displayName);

  final String displayName;
}
