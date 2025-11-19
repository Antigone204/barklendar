import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/widgets/message_list_view.dart';
import 'package:ai_smart_calendar/widgets/message_input_field.dart';

/// AI聊天页面 - 重构为组件化架构，实现"玻璃盒"效果
class AIPage extends ConsumerWidget {
  const AIPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          // 聊天消息列表 - 使用新的组件化实现
          const Expanded(
            child: MessageListView(),
          ),

          // 输入区域 - 使用新的组件化实现
          const MessageInputField(),
        ],
      ),
    );
  }
}
