class ToolCallRequest {
  final String toolName; // e.g., "calendar"
  final String functionName; // e.g., "create_event"
  final Map<String, dynamic>
      parameters; // e.g., {"title": "Team Meeting", "startTime": "..."}

  ToolCallRequest({
    required this.toolName,
    required this.functionName,
    required this.parameters,
  });

  // fromJson constructor for parsing
  factory ToolCallRequest.fromJson(Map<String, dynamic> json) {
    return ToolCallRequest(
      toolName: json['toolName'] as String,
      functionName: json['functionName'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
    );
  }

  // toJson method for serialization
  Map<String, dynamic> toJson() {
    return {
      'toolName': toolName,
      'functionName': functionName,
      'parameters': parameters,
    };
  }

  @override
  String toString() {
    return 'ToolCallRequest(toolName: $toolName, functionName: $functionName, parameters: $parameters)';
  }
}
