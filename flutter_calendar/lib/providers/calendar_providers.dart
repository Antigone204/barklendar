import 'package:flutter_riverpod/flutter_riverpod.dart';

// 创建一个 StateProvider，初始值为今天的日期
final StateProvider<DateTime> selectedDateProvider =
    StateProvider<DateTime>((StateProviderRef<DateTime> ref) {
  // 只取年月日，忽略时间
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
