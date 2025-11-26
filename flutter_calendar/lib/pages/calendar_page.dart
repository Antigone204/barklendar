import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/widgets/calendar_widget.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CalendarWidget 内部自己会处理 loading/error 状态
    // Scaffold 和 FAB 由 AdaptiveHome 管理
    return const CalendarWidget();
  }
}

