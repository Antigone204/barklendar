import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/widgets/message_list_view.dart';
import 'package:ai_smart_calendar/widgets/message_input_field.dart';

/// AI聊天页面 - 重构为组件化架构，实现"玻璃盒"效果
class AIPage extends ConsumerWidget {
  const AIPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Scaffold 由 AdaptiveHome 管理
    return const Column(
      children: <Widget>[
        // 聊天消息列表 - 使用新的组件化实现
        Expanded(
          child: MessageListView(),
        ),

        // 输入区域 - 使用新的组件化实现
        MessageInputField(),
      ],
    );
  }
}
