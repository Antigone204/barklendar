import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/providers/ai_chat_provider.dart';
import 'package:ai_smart_calendar/models/chat_message.dart';
import 'package:ai_smart_calendar/models/ai_turn_state.dart';

/// 一个通用的消息接口，用于统一处理 ChatMessage 和临时的 AiMessage
abstract class DisplayableMessage {
  String get content;
  bool get isFromUser;
}

/// 代表一个完整的、持久化的聊天消息
class PersistedMessage implements DisplayableMessage {
  final ChatMessage message;
  PersistedMessage(this.message);

  @override
  String get content => message.content;
  @override
  bool get isFromUser => message.role == 'user';
}

/// 代表一个临时的、正在流式输出的AI消息
class TemporaryAiMessage implements DisplayableMessage {
  @override
  final String content;
  final bool isPartial;

  TemporaryAiMessage({required this.content, this.isPartial = false});

  @override
  bool get isFromUser => false;
}

/// 消息列表视图 - 实现"玻璃盒"效果的AI交互界面
class MessageListView extends ConsumerStatefulWidget {
  const MessageListView({super.key});

  @override
  ConsumerState<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends ConsumerState<MessageListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 添加获取状态的代码
    final messages = ref.watch(aiChatProvider.select((s) => s.messages));
    final currentTurn = ref.watch(aiChatProvider.select((s) => s.currentTurn));

    // 修改 ListView.builder 的 itemCount
    final hasTemporaryState = currentTurn != null;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (hasTemporaryState ? 1 : 0),
      itemBuilder: (context, index) {
        // 完全替换掉 ListView.builder 的 itemBuilder 的全部内容
        if (index < messages.length) {
          // 将 ChatMessage 包装在 PersistedMessage 中
          return MessageBubble(message: PersistedMessage(messages[index]));
        }

        // 渲染临时的当前状态
        if (currentTurn != null) {
          switch (currentTurn) {
            case AiTurnStateThinking():
              return const StatusBubble(text: "思考中...", showIndicator: true);
            case AiTurnStateCallingTool(toolName: final toolName):
              return StatusBubble(
                  text: "正在调用工具: $toolName", showIndicator: true);
            case AiTurnStateStreamingContent(contentChunk: final content):
              // 将流式内容包装在 TemporaryAiMessage 中
              return MessageBubble(
                  message:
                      TemporaryAiMessage(content: content, isPartial: true));
            case AiTurnStateError(message: final errorMsg):
              return StatusBubble(text: "发生错误: $errorMsg", isError: true);
            case AiTurnStateCompleted():
              return const SizedBox.shrink();
          }
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// 用于显示状态信息（如“思考中...”、“发生错误”）的气泡
class StatusBubble extends StatelessWidget {
  final String text;
  final bool showIndicator;
  final bool isError;

  const StatusBubble({
    super.key,
    required this.text,
    this.showIndicator = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isError
            ? colorScheme.errorContainer
            : colorScheme.secondaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIndicator)
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 10),
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: textColor),
            ),
          if (isError)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(Icons.error_outline, size: 18, color: textColor),
            ),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: textColor, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

/// 用于显示用户或AI消息的气泡
class MessageBubble extends StatelessWidget {
  final DisplayableMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isFromUser;

    // 临时的、正在流式输出的消息使用斜体
    final fontStyle = (message is TemporaryAiMessage &&
            (message as TemporaryAiMessage).isPartial)
        ? FontStyle.italic
        : FontStyle.normal;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceVariant,
          borderRadius: isUser
              ? const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20))
              : const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20)),
        ),
        child: Text(
          message.content,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontStyle: fontStyle,
            color: isUser
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
