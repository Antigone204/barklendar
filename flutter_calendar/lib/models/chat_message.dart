class ChatMessage {
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  // 转换为OpenAI API格式
  Map<String, dynamic> toOpenAIMessage() {
    return <String, dynamic>{
      'role': role,
      'content': content,
    };
  }

  // 从JSON创建
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ChatMessage(role: $role, content: $content, timestamp: $timestamp)';
  }
}
