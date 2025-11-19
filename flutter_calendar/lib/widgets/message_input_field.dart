import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/providers/ai_chat_provider.dart';

/// 消息输入字段 - 负责用户输入和发送消息
class MessageInputField extends ConsumerStatefulWidget {
  const MessageInputField({super.key});

  @override
  ConsumerState<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends ConsumerState<MessageInputField> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSendEnabled = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_updateSendButtonState);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _updateSendButtonState() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (_isSendEnabled != hasText) {
      setState(() {
        _isSendEnabled = hasText;
      });
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // 使用 ref.read 而不是 ref.watch，避免不必要的重绘
    final notifier = ref.read(aiChatProvider.notifier);
    notifier.sendMessage(message);

    _messageController.clear();
    _updateSendButtonState();
  }

  @override
  Widget build(BuildContext context) {
    // 监听加载状态来控制发送按钮的可用性
    final isLoading = ref.watch(aiChatProvider.select((s) => s.isLoading));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: '输入您的问题或需求...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onChanged: (_) => _updateSendButtonState(),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: (isLoading || !_isSendEnabled) ? null : _sendMessage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary),
                    ),
                  )
                : const Text('发送'),
          ),
        ],
      ),
    );
  }
}
