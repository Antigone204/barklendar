import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/services/hive_service.dart';
import 'package:ai_smart_calendar/utils/string_utils.dart';
import 'package:ai_smart_calendar/enums/ai_prompts.dart';
import 'package:ai_smart_calendar/services/ai_service.dart' as static_ai;

class AISettingsPage extends ConsumerStatefulWidget {
  const AISettingsPage({super.key});

  @override
  ConsumerState<AISettingsPage> createState() => _AISettingsPageState();
}

class _AISettingsPageState extends ConsumerState<AISettingsPage> {
  bool showSettings = false;
  int currentIndex = 0;
  late List<Map<String, dynamic>> initialServicesConfig;
  bool _obscureApiKey = true;

  List<Map<String, dynamic>> services = [
    {
      "identifier": "openai",
      "title": "OpenAI",
      "logo": "assets/images/openai.png",
      "config": {
        "url": "https://api.openai.com/v1/chat/completions",
        "api_key": "YOUR_API_KEY",
        "model": "gpt-4o-mini",
      },
    },
    {
      "identifier": "claude",
      "title": "Claude",
      "logo": "assets/images/claude.png",
      "config": {
        "url": "https://api.anthropic.com/v1/messages",
        "api_key": "YOUR_API_KEY",
        "model": "claude-3-5-sonnet-20240620",
      },
    },
    {
      "identifier": "gemini",
      "title": "Gemini",
      "logo": "assets/images/gemini.png",
      "config": {
        "url":
            "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
        "api_key": "YOUR_API_KEY",
        "model": "gemini-2.0-flash"
      },
    },
    {
      "identifier": "deepseek",
      "title": "DeepSeek",
      "logo": "assets/images/deepseek.png",
      "config": {
        "url": "https://api.deepseek.com",
        "api_key": "YOUR_API_KEY",
        "model": "deepseek-chat",
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    initialServicesConfig = services.map((service) {
      return {
        ...service,
        'config':
            Map<String, String>.from(service['config'] as Map<String, dynamic>),
      };
    }).toList();
    _loadSavedConfig();
  }

  void _loadSavedConfig() {
    for (var service in services) {
      final savedConfig =
          HiveService.getAiConfig(service["identifier"] as String);
      if (savedConfig != null) {
        final configKeys =
            (service["config"] as Map<String, dynamic>).keys.toList();
        for (var key in configKeys) {
          if (savedConfig.containsKey(key)) {
            service["config"][key] = savedConfig[key]!;
          }
        }
      }
    }
  }

  Widget _buildAIConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            services[currentIndex]["title"] as String,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        for (String key
            in (services[currentIndex]["config"] as Map<String, dynamic>).keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              obscureText: key == "api_key" && _obscureApiKey,
              controller: TextEditingController(
                text: services[currentIndex]["config"][key]?.toString() ??
                    initialServicesConfig[currentIndex]["config"][key]
                        ?.toString() ??
                    '',
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: StringUtils.toTitleCase(key),
                hintText: services[currentIndex]["config"][key]?.toString(),
                suffixIcon: key == "api_key"
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureApiKey = !_obscureApiKey;
                          });
                        },
                        icon: _obscureApiKey
                            ? const Icon(Icons.visibility_off)
                            : const Icon(Icons.visibility),
                      )
                    : null,
              ),
              onChanged: (value) {
                services[currentIndex]["config"][key] = value;
              },
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
                onPressed: () {
                  HiveService.deleteAiConfig(
                    services[currentIndex]["identifier"] as String,
                  );
                  services[currentIndex]["config"] = Map<String, String>.from(
                      initialServicesConfig[currentIndex]["config"]
                          as Map<String, dynamic>);
                  setState(() {});
                },
                child: const Text("重置")),
            TextButton(
                onPressed: () {
                  _testAIConnection();
                },
                child: const Text("测试")),
            TextButton(
                onPressed: () {
                  _saveConfig();
                  setState(() {
                    showSettings = false;
                  });
                },
                child: const Text("保存")),
            TextButton(
                onPressed: () {
                  HiveService.selectedAiService =
                      services[currentIndex]["identifier"] as String;
                  _saveConfig();
                  setState(() {
                    showSettings = false;
                  });
                },
                child: const Text("应用")),
          ],
        )
      ],
    );
  }

  void _saveConfig() {
    HiveService.saveAiConfig(
      services[currentIndex]["identifier"] as String,
      services[currentIndex]["config"] as Map<String, dynamic>,
    );
  }

  void _testAIConnection() async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text("测试连接"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("正在测试AI连接..."),
          ],
        ),
      ),
    );

    try {
      // 调用AI服务测试连接
      final configMap =
          services[currentIndex]["config"] as Map<String, dynamic>;
      final config =
          configMap.map((key, value) => MapEntry(key, value.toString()));

      final result = await static_ai.AiService.testConnection(
        identifier: services[currentIndex]["identifier"] as String,
        config: config,
      );

      // 关闭加载对话框
      Navigator.of(context).pop();

      // 显示测试结果
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(result['success'] == true ? "连接成功" : "连接失败"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result['message'] as String),
              if (result['error'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  "错误详情: ${result['error']}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("确定"),
            ),
          ],
        ),
      );
    } catch (e) {
      // 关闭加载对话框
      Navigator.of(context).pop();

      // 显示错误信息
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("测试错误"),
          content: Text("测试过程中发生错误: $e"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("确定"),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPromptTile() {
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

    return ListView.builder(
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
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 设置'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI 服务配置
            const Text(
              'AI 服务',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildServicesSection(),
            const SizedBox(height: 24),

            // 提示词配置
            const Text(
              '提示词设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPromptTile(),
            const SizedBox(height: 24),

            // 缓存管理
            const Text(
              '缓存管理',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCacheSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: services.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () {
                    if (showSettings) {
                      if (currentIndex == index) {
                        setState(() {
                          showSettings = false;
                        });
                        return;
                      }
                      showSettings = false;
                      Future.delayed(
                        const Duration(milliseconds: 200),
                        () {
                          setState(() {
                            showSettings = true;
                            currentIndex = index;
                          });
                        },
                      );
                    } else {
                      showSettings = true;
                      currentIndex = index;
                    }
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: HiveService.selectedAiService ==
                                  (services[index]["identifier"] as String)
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Image.asset(
                          services[index]["logo"] as String,
                          width: 25,
                          height: 25,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.smart_toy, size: 25);
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(services[index]["title"] as String),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (showSettings) _buildAIConfig(),
      ],
    );
  }

  Widget _buildCacheSection() {
    return Column(
      children: [
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
    );
  }
}
