class FunctionCall {
  final String name;
  final Map<String, dynamic> arguments;

  FunctionCall({
    required this.name,
    required this.arguments,
  });

  factory FunctionCall.fromJson(Map<String, dynamic> json) {
    final dynamic rawArguments = json['arguments'];
    Map<String, dynamic> arguments = <String, dynamic>{}; // 默认为空Map

    if (rawArguments is Map) {
      // 关键：使用 Map.from 来安全地转换类型，而不是强制转换
      arguments = Map<String, dynamic>.from(rawArguments);
    }

    return FunctionCall(
      name: json['name'] as String,
      arguments: arguments,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'arguments': arguments,
    };
  }

  @override
  String toString() {
    return 'FunctionCall(name: $name, arguments: $arguments)';
  }
}

class AIResponse {
  final String content;
  final bool isDirectAnswer;
  final FunctionCall? functionCall;

  AIResponse({
    required this.content,
    this.isDirectAnswer = true,
    this.functionCall,
  });

  bool get hasFunctionCall => functionCall != null;

  factory AIResponse.directAnswer(String content) {
    return AIResponse(
      content: content,
    );
  }

  factory AIResponse.withFunctionCall(FunctionCall functionCall,
      {String content = '',}) {
    return AIResponse(
      content: content,
      isDirectAnswer: false,
      functionCall: functionCall,
    );
  }

  @override
  String toString() {
    return 'AIResponse(content: $content, isDirectAnswer: $isDirectAnswer, functionCall: $functionCall)';
  }
}
