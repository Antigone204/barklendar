import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 3)
class CategoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String color;

  @HiveField(3)
  String icon;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  int taskCount;

  @HiveField(6)
  bool isDefault;

  @HiveField(7)
  int sortOrder;

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
    this.taskCount = 0,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  // 工厂构造函数：从 JSON 创建
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      taskCount: json['taskCount'] as int? ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'taskCount': taskCount,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
    };
  }

  // 复制分类并修改某些字段
  CategoryModel copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    DateTime? createdAt,
    int? taskCount,
    bool? isDefault,
    int? sortOrder,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      taskCount: taskCount ?? this.taskCount,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  // 预定义的默认分类
  static List<CategoryModel> get defaultCategories {
    return <CategoryModel>[
      CategoryModel(
        id: 'work',
        name: '工作',
        color: '#2196F3', // 蓝色
        icon: 'work',
        createdAt: DateTime.now(),
        isDefault: true,
      ),
      CategoryModel(
        id: 'personal',
        name: '个人',
        color: '#4CAF50', // 绿色
        icon: 'person',
        createdAt: DateTime.now(),
        isDefault: true,
        sortOrder: 1,
      ),
      CategoryModel(
        id: 'shopping',
        name: '购物',
        color: '#FF9800', // 橙色
        icon: 'shopping_cart',
        createdAt: DateTime.now(),
        isDefault: true,
        sortOrder: 2,
      ),
      CategoryModel(
        id: 'health',
        name: '健康',
        color: '#E91E63', // 粉色
        icon: 'favorite',
        createdAt: DateTime.now(),
        isDefault: true,
        sortOrder: 3,
      ),
      CategoryModel(
        id: 'learning',
        name: '学习',
        color: '#9C27B0', // 紫色
        icon: 'school',
        createdAt: DateTime.now(),
        isDefault: true,
        sortOrder: 4,
      ),
      CategoryModel(
        id: 'travel',
        name: '旅行',
        color: '#FF5722', // 深橙色
        icon: 'flight',
        createdAt: DateTime.now(),
        isDefault: true,
        sortOrder: 5,
      ),
    ];
  }

  // 根据 ID 获取默认分类
  static CategoryModel? getDefaultCategoryById(String id) {
    return defaultCategories.firstWhere(
      (CategoryModel category) => category.id == id,
      orElse: () => CategoryModel(
        id: 'other',
        name: '其他',
        color: '#9E9E9E', // 灰色
        icon: 'category',
        createdAt: DateTime.now(),
        isDefault: true,
        sortOrder: 6,
      ),
    );
  }

  // 获取分类颜色对应的 MaterialColor
  Color get materialColor {
    switch (color) {
      case '#2196F3': // 蓝色
        return Colors.blue;
      case '#4CAF50': // 绿色
        return Colors.green;
      case '#FF9800': // 橙色
        return Colors.orange;
      case '#E91E63': // 粉色
        return Colors.pink;
      case '#9C27B0': // 紫色
        return Colors.purple;
      case '#FF5722': // 深橙色
        return Colors.deepOrange;
      case '#9E9E9E': // 灰色
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  // 获取分类图标
  IconData get iconData {
    switch (icon) {
      case 'work':
        return Icons.work;
      case 'person':
        return Icons.person;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'favorite':
        return Icons.favorite;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'category':
        return Icons.category;
      default:
        return Icons.category;
    }
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, taskCount: $taskCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
