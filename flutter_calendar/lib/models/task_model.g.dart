// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      createdAt: fields[3] as DateTime,
      dueDate: fields[4] as DateTime?,
      isCompleted: fields[5] as bool,
      priority: fields[6] as TaskPriority,
      categoryId: fields[7] as String,
      tags: (fields[8] as List).cast<String>(),
      reminderTime: fields[9] as DateTime?,
      hasNotification: fields[10] as bool,
      location: fields[11] as String?,
      recurrence: fields[12] as TaskRecurrence?,
      completedAt: fields[13] as DateTime?,
      aiGeneratedSuggestion: fields[14] as String?,
      reminderOffsetInMinutes: fields[15] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.dueDate)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.categoryId)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.reminderTime)
      ..writeByte(10)
      ..write(obj.hasNotification)
      ..writeByte(11)
      ..write(obj.location)
      ..writeByte(12)
      ..write(obj.recurrence)
      ..writeByte(13)
      ..write(obj.completedAt)
      ..writeByte(14)
      ..write(obj.aiGeneratedSuggestion)
      ..writeByte(15)
      ..write(obj.reminderOffsetInMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 1;

  @override
  TaskPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskPriority.low;
      case 1:
        return TaskPriority.medium;
      case 2:
        return TaskPriority.high;
      case 3:
        return TaskPriority.urgent;
      default:
        return TaskPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, TaskPriority obj) {
    switch (obj) {
      case TaskPriority.low:
        writer.writeByte(0);
        break;
      case TaskPriority.medium:
        writer.writeByte(1);
        break;
      case TaskPriority.high:
        writer.writeByte(2);
        break;
      case TaskPriority.urgent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskRecurrenceAdapter extends TypeAdapter<TaskRecurrence> {
  @override
  final int typeId = 2;

  @override
  TaskRecurrence read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskRecurrence.none;
      case 1:
        return TaskRecurrence.daily;
      case 2:
        return TaskRecurrence.weekly;
      case 3:
        return TaskRecurrence.monthly;
      case 4:
        return TaskRecurrence.yearly;
      default:
        return TaskRecurrence.none;
    }
  }

  @override
  void write(BinaryWriter writer, TaskRecurrence obj) {
    switch (obj) {
      case TaskRecurrence.none:
        writer.writeByte(0);
        break;
      case TaskRecurrence.daily:
        writer.writeByte(1);
        break;
      case TaskRecurrence.weekly:
        writer.writeByte(2);
        break;
      case TaskRecurrence.monthly:
        writer.writeByte(3);
        break;
      case TaskRecurrence.yearly:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskRecurrenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
