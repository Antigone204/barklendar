import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_smart_calendar/providers/ai_config_provider.dart';
import 'package:ai_smart_calendar/services/ai_client.dart';

class AiConfigFormPage extends ConsumerStatefulWidget {
  final Map<String, String>? config;

  const AiConfigFormPage({super.key, this.config});

  @override
  ConsumerState<AiConfigFormPage> createState() => _AiConfigFormPageState();
}

class _AiConfigFormPageState extends ConsumerState<AiConfigFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 使用 'generic', 'openai', 'deepseek' 等作为下拉选项的值
  String _selectedType = 'openai';

  // 控制器用于获取输入
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.config != null) {
      // 编辑模式：填充现有数据
      _nameController.text = widget.config!['name'] ?? '';
      _selectedType = widget.config![AiConfigKeys.type] ?? 'openai';
      _apiKeyController.text = widget.config![AiConfigKeys.apiKey] ?? '';
      _modelController.text = widget.config![AiConfigKeys.model] ?? '';
      _urlController.text = widget.config![AiConfigKeys.url] ?? '';
    } else {
      // 新建模式：设置默认值
      _nameController.text = '';
      _selectedType = 'openai';
      _apiKeyController.text = '';
      _modelController.text = '';
      _urlController.text = '';
    }
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
        title: Text(widget.config != null ? '编辑AI服务' : '添加AI服务'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '例如：OpenAI GPT-4',
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return '请输入配置名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 类型选择器
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                DropdownMenuItem(value: 'deepseek', child: Text('DeepSeek')),
                DropdownMenuItem(
                    value: 'generic', child: Text('通用 (OpenAI 兼容)'),),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
              decoration: const InputDecoration(labelText: '服务类型'),
            ),
            const SizedBox(height: 16),

            // **核心逻辑：根据类型条件性地显示URL输入框**
            if (_selectedType == 'generic')
              Column(
                children: <Widget>[
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'API Base URL',
                      hintText: '例如：https://api.example.com/v1',
                    ),
                    validator: (String? value) {
                      if (_selectedType == 'generic' &&
                          (value == null || value.isEmpty)) {
                        return '通用类型必须提供URL';
                      }
                      if (value != null &&
                          value.isNotEmpty &&
                          !_isValidUrl(value)) {
                        return '请输入有效的URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            TextFormField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: '请输入您的API密钥',
              ),
              obscureText: true,
              validator: (String? value) {
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
                labelText: '模型名称',
                hintText: '例如：gpt-3.5-turbo',
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return '请输入模型名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                _saveConfig();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(widget.config != null ? '更新配置' : '保存配置'),
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

  void _saveConfig() {
    if (_formKey.currentState!.validate()) {
      final Map<String, String> config = <String, String>{
        'name': _nameController.text,
        AiConfigKeys.type: _selectedType,
        AiConfigKeys.apiKey: _apiKeyController.text,
        AiConfigKeys.model: _modelController.text,
      };

      // 只有通用类型才需要URL
      if (_selectedType == 'generic') {
        config[AiConfigKeys.url] = _urlController.text;
      } else {
        // 对于非通用类型，使用预设的URL
        switch (_selectedType) {
          case 'openai':
            config[AiConfigKeys.url] = 'https://api.openai.com/v1';
            break;
          case 'deepseek':
            config[AiConfigKeys.url] = 'https://api.deepseek.com/v1';
            break;
        }
      }

      // 如果是编辑模式，保留原有的ID
      if (widget.config != null && widget.config!['id'] != null) {
        config['id'] = widget.config!['id']!;
      }

      final AiConfigNotifier notifier = ref.read(aiConfigProvider.notifier);

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

      if (context.canPop()) {
        context.pop();
      }
    }
  }
}
