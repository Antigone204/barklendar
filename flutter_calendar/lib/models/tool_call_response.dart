class ToolCallResponse {
  final String toolName;
  final String functionName;
  final bool isSuccess;
  final dynamic result; // Can be a message, a list of events, etc.
  final String? error;

  ToolCallResponse({
    required this.toolName,
    required this.functionName,
    required this.isSuccess,
    this.result,
    this.error,
  });

  // fromJson constructor for parsing
  factory ToolCallResponse.fromJson(Map<String, dynamic> json) {
    return ToolCallResponse(
      toolName: json['toolName'] as String,
      functionName: json['functionName'] as String,
      isSuccess: json['isSuccess'] as bool,
      result: json['result'],
      error: json['error'] as String?,
    );
  }

  // toJson method for serialization
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'toolName': toolName,
      'functionName': functionName,
      'isSuccess': isSuccess,
      'result': result,
      'error': error,
    };
  }

  // Success response factory
  factory ToolCallResponse.success({
    required String toolName,
    required String functionName,
    dynamic result,
  }) {
    return ToolCallResponse(
      toolName: toolName,
      functionName: functionName,
      isSuccess: true,
      result: result,
    );
  }

  // Error response factory
  factory ToolCallResponse.error({
    required String toolName,
    required String functionName,
    required String error,
  }) {
    return ToolCallResponse(
      toolName: toolName,
      functionName: functionName,
      isSuccess: false,
      error: error,
    );
  }

  @override
  String toString() {
    return 'ToolCallResponse(toolName: $toolName, functionName: $functionName, isSuccess: $isSuccess, result: $result, error: $error)';
  }
}
