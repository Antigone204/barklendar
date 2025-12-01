import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_smart_calendar/providers/ai_config_provider.dart';
import 'package:ai_smart_calendar/services/ai_client.dart';

class AiConfigListPage extends ConsumerWidget {
  const AiConfigListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AiConfigState> aiConfigState = ref.watch(aiConfigProvider);

    return aiConfigState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) =>
          Center(child: Text('加载失败: $error')),
      data: (AiConfigState state) {
        final List<Map<String, String>> configs = state.configs;
        final String activeConfigId = state.activeConfigId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI服务配置'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: configs.isEmpty
              ? const Center(
                  child: Text('暂无AI服务配置'),
                )
              : ListView.builder(
                  itemCount: configs.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, String> config = configs[index];
                    final bool isActive = config['id'] == activeConfigId;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: isActive
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : const Icon(Icons.circle_outlined),
                        title: Text(
                          config['name'] ?? '未命名配置',
                          style: TextStyle(
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '类型: ${_getServiceTypeName(config[AiConfigKeys.type])}',
                            ),
                            if (config[AiConfigKeys.model]?.isNotEmpty == true)
                              Text('模型: ${config[AiConfigKeys.model]}'),
                            if (config[AiConfigKeys.url]?.isNotEmpty == true)
                              Text('URL: ${config[AiConfigKeys.url]}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _navigateToFormPage(context, config: config);
                              },
                              tooltip: '编辑配置',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteDialog(context, ref, config);
                              },
                              tooltip: '删除配置',
                            ),
                          ],
                        ),
                        onTap: () {
                          if (!isActive) {
                            ref
                                .read(aiConfigProvider.notifier)
                                .setActiveConfig(config['id']!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('已切换到 ${config['name']}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _navigateToFormPage(context);
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  String _getServiceTypeName(String? type) {
    switch (type) {
      case 'openai':
        return 'OpenAI';
      case 'deepseek':
        return 'DeepSeek';
      case 'generic':
        return '通用服务';
      default:
        return '未知';
    }
  }

  void _navigateToFormPage(
    BuildContext context, {
    Map<String, String>? config,
  }) {
    context.pushNamed('ai_service_detail', extra: config);
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, String> config,
  ) {
    final BuildContext pageContext = context;

    // 【修改点】在这里加上 <void>
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('删除配置'),
          content: Text('确定要删除 "${config['name']}" 配置吗？'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (dialogContext.mounted) {
                  // 建议：使用 mounted 检查更安全
                  Navigator.of(dialogContext).pop(); // 建议：显式调用 Navigator
                }
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                ref.read(aiConfigProvider.notifier).deleteConfig(config['id']!);

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                // 注意：如果页面被销毁，这里可能会报错，最好加个 mounted 判断
                if (pageContext.mounted) {
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Text('已删除 ${config['name']}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
