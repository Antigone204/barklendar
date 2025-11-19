sealed class AiTurnState {
  const AiTurnState();
}

/// AI正在思考，等待LLM的初步决策
class AiTurnStateThinking extends AiTurnState {
  const AiTurnStateThinking();
}

/// AI决定调用工具，并告知UI它正在做什么
class AiTurnStateCallingTool extends AiTurnState {
  final String toolName;
  final String functionName;
  final Map<String, dynamic> parameters;

  const AiTurnStateCallingTool({
    required this.toolName,
    required this.functionName,
    required this.parameters,
  });
}

/// AI正在流式输出最终的文本内容
class AiTurnStateStreamingContent extends AiTurnState {
  final String contentChunk;
  final bool isComplete;

  const AiTurnStateStreamingContent({
    required this.contentChunk,
    this.isComplete = false,
  });
}

/// AI交互完成，包含完整结果
class AiTurnStateCompleted extends AiTurnState {
  final String finalContent;

  const AiTurnStateCompleted({
    required this.finalContent,
  });
}

/// AI交互出错
class AiTurnStateError extends AiTurnState {
  final String message;

  const AiTurnStateError({
    required this.message,
  });
}

// 为状态模型添加扩展方法，便于使用
extension AiTurnStateExtensions on AiTurnState {
  bool get isThinking => this is AiTurnStateThinking;
  bool get isCallingTool => this is AiTurnStateCallingTool;
  bool get isStreamingContent => this is AiTurnStateStreamingContent;
  bool get isCompleted => this is AiTurnStateCompleted;
  bool get isError => this is AiTurnStateError;

  // 类型安全的getter
  AiTurnStateCallingTool? get asCallingTool =>
      this is AiTurnStateCallingTool ? this as AiTurnStateCallingTool : null;
  AiTurnStateStreamingContent? get asStreamingContent =>
      this is AiTurnStateStreamingContent
          ? this as AiTurnStateStreamingContent
          : null;
}
