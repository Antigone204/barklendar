import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_smart_calendar/providers/ai_config_provider.dart';
import 'package:ai_smart_calendar/services/ai_client.dart';
import 'package:ai_smart_calendar/services/ai_factory.dart';
import 'package:ai_smart_calendar/services/ai_service_interface.dart';
import 'package:ai_smart_calendar/services/ai_service.dart' as static_ai;
import 'package:ai_smart_calendar/services/hive_service.dart';
import 'package:ai_smart_calendar/enums/ai_prompts.dart';
import 'package:ai_smart_calendar/utils/string_utils.dart';

class AiServiceDetailPage extends ConsumerStatefulWidget {
  final Map<String, String>? config;

  const AiServiceDetailPage({super.key, this.config});

  @override
  ConsumerState<AiServiceDetailPage> createState() =>
      _AiServiceDetailPageState();
}

class _AiServiceDetailPageState extends ConsumerState<AiServiceDetailPage> {
  final _formKey = GlobalKey<FormState>();

  // 预设数据
  final Map<String, Map<String, String>> _presets = {
    'openai': {
      'name': 'OpenAI',
      'url': 'https://api.openai.com/v1',
    },
    'deepseek': {
      'name': 'DeepSeek',
      'url': 'https://api.deepseek.com/v1',
    },
    'qwen': {
      'name': '通义千问',
      'url':
          'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
    },
    'lmstudio': {
      'name': 'LM Studio',
      'url': 'http://localhost:1234/v1',
    },
    'custom': {
      'name': '自定义',
      'url': '',
    },
  };

  // 表单控制器
  String _selectedPreset = 'openai';
  final _nameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  final _urlController = TextEditingController();

  // 异步操作状态
  bool _isTestingConnection = false;
  bool _isSavingConfig = false;
  bool _isSettingActive = false;
  bool _isDeleting = false;

  // API Key 显示状态
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.config != null) {
      // 编辑模式：填充现有数据
      _nameController.text = widget.config!['name'] ?? '';
      _apiKeyController.text = widget.config![AiConfigKeys.apiKey] ?? '';
      _modelController.text = widget.config![AiConfigKeys.model] ?? '';
      _urlController.text = widget.config![AiConfigKeys.url] ?? '';

      // 根据URL确定预设
      _selectedPreset = _determinePresetFromUrl(_urlController.text);
    } else {
      // 新建模式：设置默认值
      _nameController.text = '';
      _selectedPreset = 'openai';
      _apiKeyController.text = '';
      _modelController.text = '';
      _urlController.text = _presets['openai']!['url']!;
    }
  }

  String _determinePresetFromUrl(String url) {
    for (var entry in _presets.entries) {
      if (entry.key != 'custom' && url == entry.value['url']) {
        return entry.key;
      }
    }
    return 'custom';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config != null ? 'AI服务详情' : '添加AI服务'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. 配置表单部分
            _buildConfigForm(),
            const SizedBox(height: 24),

            // B. 核心操作按钮
            _buildActionButtons(),
            const SizedBox(height: 24),

            // C. 提示词设置部分
            _buildPromptSettings(),
            const SizedBox(height: 24),

            // D. 缓存管理部分
            _buildCacheSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '服务配置',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "名称",
                  hintText: "例如：OpenAI GPT-4",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入配置名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 服务预设选择器
              DropdownButtonFormField<String>(
                value: _selectedPreset,
                items: _presets.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPreset = value;
                      // 核心逻辑：根据选择的预设，自动更新URL控制器
                      _urlController.text = _presets[value]!['url']!;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: "服务预设"),
              ),
              const SizedBox(height: 16),

              // URL输入框（始终显示，用户可以手动调整）
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: "API Base URL",
                  hintText: "例如：https://api.example.com/v1",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入API Base URL';
                  }
                  if (!_isValidUrl(value)) {
                    return '请输入有效的URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: "API Key",
                  hintText: "请输入您的API密钥",
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureApiKey = !_obscureApiKey;
                      });
                    },
                    icon: _obscureApiKey
                        ? const Icon(Icons.visibility_off)
                        : const Icon(Icons.visibility),
                  ),
                ),
                obscureText: _obscureApiKey,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入API密钥';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: "模型名称",
                  hintText: "例如：gpt-3.5-turbo",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入模型名称';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final aiConfigState = ref.watch(aiConfigProvider);
    final isActive = aiConfigState.when(
      data: (state) =>
          widget.config != null && widget.config!['id'] == state.activeConfigId,
      loading: () => false,
      error: (_, __) => false,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '操作',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 连接测试按钮
                ElevatedButton.icon(
                  onPressed: _isTestingConnection ? null : _testConnection,
                  icon: _isTestingConnection
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering, size: 16),
                  label: const Text('连接测试'),
                ),

                // 保存配置按钮
                ElevatedButton.icon(
                  onPressed: _isSavingConfig ? null : _saveConfig,
                  icon: _isSavingConfig
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save, size: 16),
                  label: Text(widget.config != null ? '更新配置' : '保存配置'),
                ),

                // 设为激活按钮（仅在编辑模式且非当前激活配置时显示）
                if (widget.config != null && !isActive)
                  ElevatedButton.icon(
                    onPressed: _isSettingActive ? null : _setAsActive,
                    icon: _isSettingActive
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.star, size: 16),
                    label: const Text('设为激活'),
                  ),

                // 删除按钮（仅在编辑模式时显示）
                if (widget.config != null)
                  ElevatedButton.icon(
                    onPressed: _isDeleting ? null : _showDeleteDialog,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete, size: 16),
                    label: const Text('删除'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSettings() {
    final prompts = [
      {
        "identifier": AiPrompts.test,
        "title": "测试提示词",
        "variables": ["language_locale"],
      },
      {
        "identifier": AiPrompts.summarizeDay,
        "title": "每日日程总结",
        "variables": ["date", "tasks"],
      },
      {
        "identifier": AiPrompts.summarizeWeek,
        "title": "每周日程总结",
        "variables": ["start_date", "end_date", "tasks"],
      },
      {
        "identifier": AiPrompts.createEvent,
        "title": "创建日程事件",
        "variables": ["title", "description", "date", "time"],
      },
      {
        "identifier": AiPrompts.suggestTime,
        "title": "建议空闲时间",
        "variables": ["busy_times", "duration"],
      },
      {
        "identifier": AiPrompts.analyzeProductivity,
        "title": "分析工作效率",
        "variables": ["completed_tasks", "pending_tasks"],
      }
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '提示词设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: prompts.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(prompts[index]["title"] as String),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _editPrompt(prompts[index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '缓存管理',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("缓存大小"),
              subtitle: Slider(
                value: HiveService.maxAiCacheCount.toDouble(),
                min: 0,
                max: 1000,
                divisions: 100,
                onChanged: (value) {
                  HiveService.maxAiCacheCount = value.toInt();
                  setState(() {});
                },
              ),
              trailing: Text("${HiveService.maxAiCacheCount} 条"),
            ),
            ListTile(
              title: const Text("清空缓存"),
              trailing: const Icon(Icons.delete),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("确认清空"),
                    content: const Text("确定要清空所有AI缓存吗？此操作不可撤销。"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("取消"),
                      ),
                      TextButton(
                        onPressed: () {
                          HiveService.clearAiCache();
                          Navigator.of(context).pop();
                          setState(() {});
                        },
                        child: const Text("确认"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isTestingConnection = true;
    });

    try {
      // 从表单获取当前值
      final currentConfig = <String, String>{
        'name': _nameController.text,
        AiConfigKeys.type: 'generic', // 所有服务都使用通用类型
        AiConfigKeys.apiKey: _apiKeyController.text,
        AiConfigKeys.model: _modelController.text,
        AiConfigKeys.url: _urlController.text, // 总是使用URL控制器中的值
      };

      // 使用 AiService 测试连接
      final result = await static_ai.AiService.testConnection(
        identifier: 'generic', // 统一使用通用类型
        config: currentConfig,
      );

      // 显示测试结果
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? '连接测试成功！'
              : '连接测试失败：${result['message']}'),
          backgroundColor:
              result['success'] == true ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('测试出错: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSavingConfig = true;
    });

    try {
      final config = <String, String>{
        'name': _nameController.text,
        AiConfigKeys.type: 'generic', // 所有服务都使用通用类型
        AiConfigKeys.apiKey: _apiKeyController.text,
        AiConfigKeys.model: _modelController.text,
        AiConfigKeys.url: _urlController.text, // 总是使用URL控制器中的值
      };

      // 如果是编辑模式，保留原有的ID
      if (widget.config != null && widget.config!['id'] != null) {
        config['id'] = widget.config!['id']!;
      }

      final notifier = ref.read(aiConfigProvider.notifier);

      if (widget.config != null) {
        // 更新配置
        notifier.updateConfig(config['id']!, config);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('配置更新成功'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // 添加新配置
        notifier.addConfig(config);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('配置添加成功'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 延迟返回，让用户看到成功消息
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSavingConfig = false;
      });
    }
  }

  Future<void> _setAsActive() async {
    if (widget.config == null || widget.config!['id'] == null) {
      return;
    }

    setState(() {
      _isSettingActive = true;
    });

    try {
      ref
          .read(aiConfigProvider.notifier)
          .setActiveConfig(widget.config!['id']!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已将 ${widget.config!['name']} 设为激活服务'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('设置激活失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSettingActive = false;
      });
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除配置'),
          content: Text('确定要删除 "${widget.config!['name']}" 配置吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                _deleteConfig();
                Navigator.of(context).pop();
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteConfig() async {
    if (widget.config == null || widget.config!['id'] == null) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      ref.read(aiConfigProvider.notifier).deleteConfig(widget.config!['id']!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除 ${widget.config!['name']}'),
          duration: const Duration(seconds: 2),
        ),
      );

      // 延迟返回，让用户看到成功消息
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  void _editPrompt(Map<String, dynamic> prompt) {
    final controller = TextEditingController(
      text: HiveService.getAiPrompt(prompt["identifier"])?.toString() ??
          "默认提示词内容",
    );

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("编辑提示词"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  maxLines: 10,
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                Wrap(
                  children: [
                    for (var variable in prompt["variables"] as List<String>)
                      TextButton(
                        onPressed: () {
                          final selection = controller.selection;
                          if (selection.start == -1 || selection.end == -1) {
                            return;
                          }
                          controller.text = controller.text.replaceRange(
                            selection.start,
                            selection.end,
                            '{{$variable}}',
                          );
                        },
                        child: Text('{{$variable}}'),
                      ),
                  ],
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  HiveService.deleteAiPrompt(prompt["identifier"]);
                  Navigator.of(context).pop();
                },
                child: const Text("重置"),
              ),
              TextButton(
                onPressed: () {
                  HiveService.saveAiPrompt(
                    prompt["identifier"],
                    controller.text,
                  );
                  Navigator.of(context).pop();
                },
                child: const Text("保存"),
              ),
            ],
          );
        });
  }
}
