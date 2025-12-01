import 'package:ai_smart_calendar/models/tool_definition.dart';

/// 工具注册服务 - 所有可用工具的中心注册表
class ToolRegistryService {
  final List<ToolDefinition> _toolDefinitions = <ToolDefinition>[];

  /// 注册工具
  void registerTool(ToolDefinition toolDefinition) {
    _toolDefinitions.add(toolDefinition);
  }

  /// 获取所有工具定义
  List<ToolDefinition> getToolDefinitions() {
    return List.unmodifiable(_toolDefinitions);
  }

  /// 根据工具名称查找工具定义
  ToolDefinition? getToolDefinitionByName(String toolName) {
    return _toolDefinitions.firstWhere(
      (ToolDefinition tool) => tool.name == toolName,
      orElse: () => throw Exception('未找到工具: $toolName'),
    );
  }

  /// 根据函数名称查找函数定义
  FunctionDefinition? getFunctionDefinition(String functionName) {
    for (final ToolDefinition tool in _toolDefinitions) {
      for (final FunctionDefinition function in tool.functions) {
        if (function.name == functionName) {
          return function;
        }
      }
    }
    return null;
  }

  /// 生成AI系统提示词 - 核心功能！
  /// 这个提示词将被注入到AI的系统消息中，告诉AI它可以使用哪些工具
  String generateToolPrompt() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('## 可用工具列表');
    buffer.writeln('您可以使用以下工具来帮助用户：');

    for (final ToolDefinition tool in _toolDefinitions) {
      buffer.writeln('\n### ${tool.name}');
      buffer.writeln(tool.description);

      for (final FunctionDefinition function in tool.functions) {
        buffer.writeln('- **${function.name}**: ${function.description}');

        // 添加参数说明
        final Map<String, dynamic>? parameters =
            function.parameters['properties'] as Map<String, dynamic>?;
        if (parameters != null && parameters.isNotEmpty) {
          buffer.writeln('  参数:');
          for (final MapEntry<String, dynamic> paramEntry in parameters.entries) {
            final String paramName = paramEntry.key;
            final Map<String, dynamic> paramInfo = paramEntry.value as Map<String, dynamic>;
            final paramType = paramInfo['type'] ?? 'any';
            final paramDesc = paramInfo['description'] ?? '';

            // 检查是否为必需参数
            final List requiredParams =
                function.parameters['required'] as List<dynamic>? ?? <dynamic>[];
            final bool isRequired = requiredParams.contains(paramName);

            buffer.writeln(
                '  - $paramName ($paramType${isRequired ? ', 必需' : ''}): $paramDesc',);
          }
        }
      }
    }

    buffer.writeln('\n## 使用说明');
    buffer.writeln('当用户请求涉及上述功能时，请选择合适的工具函数并调用。');
    buffer.writeln('确保提供所有必需参数，并遵循参数格式要求。');
    buffer.writeln('对于日期参数，请使用ISO 8601格式 (例如: 2023-12-01T10:00:00Z)。');

    return buffer.toString();
  }

  /// 生成JSON格式的工具描述（用于OpenAI等模型的function calling）
  List<Map<String, dynamic>> generateToolSchemas() {
    return _toolDefinitions.expand((ToolDefinition tool) => tool.functions).map((FunctionDefinition function) {
      // 关键：将函数定义包装在 {"type": "function", "function": ...} 结构中
      return <String, Object>{
        'type': 'function',
        'function': function.toJsonSchema(),
      };
    }).toList();
  }

  /// 获取所有可用的函数名称列表
  List<String> getAvailableFunctionNames() {
    return _toolDefinitions
        .expand((ToolDefinition tool) => tool.functions)
        .map((FunctionDefinition function) => function.name)
        .toList();
  }

  /// 验证函数调用参数
  Map<String, dynamic>? validateFunctionParameters(
      String functionName, Map<String, dynamic> parameters,) {
    final FunctionDefinition? functionDef = getFunctionDefinition(functionName);
    if (functionDef == null) {
      return <String, dynamic>{'valid': false, 'error': '未知的函数: $functionName'};
    }

    final List requiredParams =
        functionDef.parameters['required'] as List<dynamic>? ?? <dynamic>[];
    final List<String> missingParams = <String>[];

    // 检查必需参数
    for (final requiredParam in requiredParams) {
      if (!parameters.containsKey(requiredParam)) {
        missingParams.add(requiredParam as String);
      }
    }

    if (missingParams.isNotEmpty) {
      return <String, dynamic>{'valid': false, 'error': '缺少必需参数: ${missingParams.join(', ')}'};
    }

    // 这里可以添加更复杂的参数验证逻辑
    // 比如类型检查、枚举值验证等

    return <String, dynamic>{'valid': true};
  }

  /// 获取工具统计信息
  Map<String, dynamic> getToolStatistics() {
    final int totalFunctions =
        _toolDefinitions.fold(0, (int sum, ToolDefinition tool) => sum + tool.functions.length);

    return <String, dynamic>{
      'totalTools': _toolDefinitions.length,
      'totalFunctions': totalFunctions,
      'tools': _toolDefinitions
          .map((ToolDefinition tool) => <String, Object>{
                'name': tool.name,
                'functionCount': tool.functions.length,
                'functions': tool.functions.map((FunctionDefinition f) => f.name).toList(),
              },)
          .toList(),
    };
  }
}
