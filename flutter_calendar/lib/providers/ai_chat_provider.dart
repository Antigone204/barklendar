import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/models/ai_turn_state.dart';
import 'package:ai_smart_calendar/models/chat_message.dart';
import 'package:ai_smart_calendar/services/tool_calling_service.dart';
import 'package:ai_smart_calendar/providers/repository_providers.dart';

/// AI聊天状态 - V2版本，支持流式交互
class AiChatV2State {
  final List<ChatMessage> messages;
  final AiTurnState? currentTurnState;
  final AiTurnState? currentTurn;
  final bool isLoading;

  const AiChatV2State({
    required this.messages,
    this.currentTurnState,
    this.currentTurn,
    this.isLoading = false,
  });

  AiChatV2State copyWith({
    List<ChatMessage>? messages,
    AiTurnState? currentTurnState,
    AiTurnState? currentTurn,
    bool? isLoading,
  }) {
    return AiChatV2State(
      messages: messages ?? this.messages,
      currentTurnState: currentTurnState ?? this.currentTurnState,
      currentTurn: currentTurn ?? this.currentTurn,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// AI聊天 Provider - 全新的状态流管理器
final StateNotifierProvider<AiChatV2Notifier, AiChatV2State> aiChatProvider =
    StateNotifierProvider<AiChatV2Notifier, AiChatV2State>((StateNotifierProviderRef<AiChatV2Notifier, AiChatV2State> ref) {
  final ToolCallingService toolCallingService = ref.read(toolCallingServiceProvider);
  return AiChatV2Notifier(toolCallingService: toolCallingService);
});

class AiChatV2Notifier extends StateNotifier<AiChatV2State> {
  final ToolCallingService _toolCallingService;
  String _currentStreamingContent = '';

  AiChatV2Notifier({
    required ToolCallingService toolCallingService,
  })  : _toolCallingService = toolCallingService,
        super(const AiChatV2State(
            messages: <ChatMessage>[],),);

  /// 发送用户消息并开始AI交互（流式版本）
  Future<void> sendMessage(String userMessage) async {
    // 准备开始：设置加载状态并清空临时的流内容
    state = state.copyWith(isLoading: true);
    _currentStreamingContent = '';

    // 将用户消息立即添加到历史记录中
    final ChatMessage userChatMessage = ChatMessage(
      role: 'user',
      content: userMessage,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: <ChatMessage>[...state.messages, userChatMessage]);

    // 创建新的AI响应流
    final Stream<AiTurnState> turnStream = _toolCallingService.executeTurnStream(
      userMessage,
      history: state.messages,
    );

    // 使用 try...finally 结构，确保状态总能被清理
    try {
      // 开始时，向UI报告“正在思考”
      state = state.copyWith(currentTurn: const AiTurnStateThinking());

      // 使用 await for 线性、顺序地处理流中的每一个状态
      await for (final AiTurnState aiState in turnStream) {
        // 将流中的每一个状态，实时更新到 state 中，供UI渲染
        state = state.copyWith(currentTurn: aiState);

        // 同时，累积最终的流式内容，为持久化做准备
        if (aiState is AiTurnStateStreamingContent) {
          _currentStreamingContent =
              aiState.contentChunk; // 假设 contentChunk 是完整的累积内容
        }
      }
    } catch (e) {
      // 如果流处理过程中发生错误，向UI报告错误状态
      state =
          state.copyWith(currentTurn: AiTurnStateError(message: e.toString()));
    } finally {
      // 当 await for 循环正常结束或因错误退出时，finally 块保证执行
      final List<ChatMessage> finalMessages = List<ChatMessage>.from(state.messages);

      // 只有当真实产生了流式内容时，才将其添加到最终的历史记录中
      if (_currentStreamingContent.isNotEmpty) {
        final ChatMessage finalAiMessage = ChatMessage(
          role: 'assistant',
          content: _currentStreamingContent,
          timestamp: DateTime.now(),
        );
        finalMessages.add(finalAiMessage);
      }

      // 执行最终的、原子性的状态更新
      state = state.copyWith(
        messages: finalMessages,
        isLoading: false,
      );
      _currentStreamingContent = ''; // 清理临时内容变量
    }
  }

  /// 清除聊天记录
  void clearMessages() {
    state = const AiChatV2State(messages: <ChatMessage>[]);
  }

  /// 取消当前交互
  void cancelCurrentInteraction() {
    state = state.copyWith(
      isLoading: false,
    );
  }

}
