import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_smart_calendar/theme/app_theme.dart' as app_theme;
import 'package:ai_smart_calendar/main.dart';
import 'package:ai_smart_calendar/pages/ai_settings_page.dart';
import 'package:ai_smart_calendar/services/hive_service.dart';
import 'package:ai_smart_calendar/utils/app_constants.dart';
import 'package:ai_smart_calendar/utils/logger.dart';
import 'package:ai_smart_calendar/l10n/app_localizations.dart';
import 'package:ai_smart_calendar/providers/locale_provider.dart';
import 'package:ai_smart_calendar/providers/tasks_provider.dart';
import 'package:ai_smart_calendar/providers/calendar_providers.dart';
import 'package:ai_smart_calendar/providers/ai_config_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _taskRemindersEnabled = true;
  bool _dailyDigestEnabled = true;
  final bool _darkModeEnabled = false;
  bool _aiSuggestionsEnabled = true;
  String _language = '中文';
  String _themeColor = '蓝色';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _notificationsEnabled = HiveService.getSetting(
          AppConstants.notificationsEnabled,
          defaultValue: AppConstants.defaultNotificationsEnabled) as bool;
      _taskRemindersEnabled = HiveService.getSetting(
          AppConstants.taskRemindersEnabled,
          defaultValue: AppConstants.defaultTaskRemindersEnabled) as bool;
      _dailyDigestEnabled = HiveService.getSetting(
          AppConstants.dailyDigestEnabled,
          defaultValue: AppConstants.defaultDailyDigestEnabled) as bool;

      // 加载语言设置
      _language = HiveService.getSetting(AppConstants.languageSetting,
          defaultValue: AppConstants.defaultLanguage) as String;
    });

    // 日志输出：通知设置加载完成
    Logger.logNotificationSettings('设置加载完成', {
      '通知启用': _notificationsEnabled,
      '任务提醒': _taskRemindersEnabled,
      '每日摘要': _dailyDigestEnabled,
      '语言': _language,
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // 外观设置
          _buildSectionHeader(AppLocalizations.of(context)!.appearanceSettings),
          _buildThemeSetting(),
          const SizedBox(height: 16),
          _buildColorSetting(),
          const SizedBox(height: 24),

          // 通知设置
          _buildSectionHeader(
              AppLocalizations.of(context)!.notificationSettings),
          _buildNotificationSetting(),
          const SizedBox(height: 24),

          // AI 设置
          _buildSectionHeader(AppLocalizations.of(context)!.aiSettings),
          _buildAISetting(),
          const SizedBox(height: 24),

          // AI 配置
          _buildSectionHeader(AppLocalizations.of(context)!.aiConfiguration),
          _buildAIConfigSetting(),
          const SizedBox(height: 24),

          // 语言设置
          _buildSectionHeader(AppLocalizations.of(context)!.language),
          _buildLanguageSetting(),
          const SizedBox(height: 24),

          // 数据管理
          _buildSectionHeader(AppLocalizations.of(context)!.dataManagement),
          _buildDataManagement(),
          const SizedBox(height: 24),

          // 关于
          _buildSectionHeader(AppLocalizations.of(context)!.about),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _buildThemeSetting() {
    final app_theme.ThemeNotifier themeNotifier =
        ref.read(themeNotifierProvider);
    final bool isDarkMode = themeNotifier.mode == ThemeMode.dark;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.dark_mode),
        title: Text(AppLocalizations.of(context)!.darkMode),
        trailing: Switch(
          value: isDarkMode,
          onChanged: (bool value) {
            themeNotifier.setMode(value ? ThemeMode.dark : ThemeMode.light);
          },
        ),
      ),
    );
  }

  Widget _buildColorSetting() {
    final app_theme.ThemeNotifier themeNotifier =
        ref.watch(themeNotifierProvider);

    // 获取当前颜色对应的名称
    String getColorName(Color color) {
      if (color == Colors.blue) return AppLocalizations.of(context)!.blue;
      if (color == Colors.green) return AppLocalizations.of(context)!.green;
      if (color == Colors.orange) return AppLocalizations.of(context)!.orange;
      if (color == Colors.purple) return AppLocalizations.of(context)!.purple;
      if (color == Colors.pink) return AppLocalizations.of(context)!.pink;
      if (color == Colors.blueAccent)
        return AppLocalizations.of(context)!.blueAccent;
      if (color == Colors.cyan) return AppLocalizations.of(context)!.cyan;
      if (color == Colors.red) return AppLocalizations.of(context)!.red;
      return AppLocalizations.of(context)!.customColor;
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.palette),
        title: Text(AppLocalizations.of(context)!.themeColor),
        subtitle: Text(getColorName(themeNotifier.primaryColor)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showColorPicker,
      ),
    );
  }

  Widget _buildNotificationSetting() {
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(AppLocalizations.of(context)!.enableNotifications),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (bool value) {
                // 记录设置变更
                Logger.logSettingChange(
                  AppConstants.notificationsEnabled,
                  _notificationsEnabled,
                  value,
                );

                // 记录持久化操作
                Logger.logPersistenceOperation(
                  AppLocalizations.of(context)!.saveNotificationSettings,
                  AppConstants.notificationsEnabled,
                  value,
                );

                HiveService.saveSetting(
                    AppConstants.notificationsEnabled, value);
                setState(() {
                  _notificationsEnabled = value;
                  // 如果总开关关闭，自动关闭所有子开关
                  if (!value) {
                    _taskRemindersEnabled = false;
                    _dailyDigestEnabled = false;
                    HiveService.saveSetting(
                        AppConstants.taskRemindersEnabled, false);
                    HiveService.saveSetting(
                        AppConstants.dailyDigestEnabled, false);
                  }
                });
              },
            ),
          ),
          if (_notificationsEnabled) ...<Widget>[
            const Divider(height: 1),
            ListTile(
              title: Text(AppLocalizations.of(context)!.taskReminders),
              trailing: Switch(
                value: _taskRemindersEnabled,
                onChanged: _notificationsEnabled
                    ? (bool value) {
                        // 记录设置变更
                        Logger.logSettingChange(
                          AppConstants.taskRemindersEnabled,
                          _taskRemindersEnabled,
                          value,
                        );

                        // 记录持久化操作
                        Logger.logPersistenceOperation(
                          AppLocalizations.of(context)!
                              .saveTaskReminderSettings,
                          AppConstants.taskRemindersEnabled,
                          value,
                        );

                        HiveService.saveSetting(
                            AppConstants.taskRemindersEnabled, value);
                        setState(() {
                          _taskRemindersEnabled = value;
                        });
                      }
                    : null,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(AppLocalizations.of(context)!.dailyDigest),
              trailing: Switch(
                value: _dailyDigestEnabled,
                onChanged: _notificationsEnabled
                    ? (bool value) {
                        // 记录设置变更
                        Logger.logSettingChange(
                          AppConstants.dailyDigestEnabled,
                          _dailyDigestEnabled,
                          value,
                        );

                        // 记录持久化操作
                        Logger.logPersistenceOperation(
                          AppLocalizations.of(context)!.saveDailyDigestSettings,
                          AppConstants.dailyDigestEnabled,
                          value,
                        );

                        HiveService.saveSetting(
                            AppConstants.dailyDigestEnabled, value);
                        setState(() {
                          _dailyDigestEnabled = value;
                        });
                      }
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAISetting() {
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: Text(AppLocalizations.of(context)!.aiSmartSuggestions),
            trailing: Switch(
              value: _aiSuggestionsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _aiSuggestionsEnabled = value;
                });
                // TODO: 更新 AI 设置
              },
            ),
          ),
          if (_aiSuggestionsEnabled) ...<Widget>[
            const Divider(height: 1),
            ListTile(
              title: Text(AppLocalizations.of(context)!.taskOptimization),
              trailing: Switch(
                value: true,
                onChanged: (bool value) {
                  // TODO: 更新任务优化设置
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(AppLocalizations.of(context)!.timePlanning),
              trailing: Switch(
                value: true,
                onChanged: (bool value) {
                  // TODO: 更新时间规划设置
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIConfigSetting() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.api),
        title: const Text('AI服务管理'),
        subtitle: const Text('管理、测试和配置多个AI服务及提示词'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.pushNamed('ai_configs');
        },
      ),
    );
  }

  Widget _buildLanguageSetting() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.language),
        title: Text(AppLocalizations.of(context)!.language),
        subtitle: Text(_language),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showLanguagePicker,
      ),
    );
  }

  Widget _buildDataManagement() {
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(AppLocalizations.of(context)!.backupData),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _backupData,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(AppLocalizations.of(context)!.restoreData),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _restoreData,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete),
            title: Text(AppLocalizations.of(context)!.clearData),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _clearData,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(AppLocalizations.of(context)!.aboutApp),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showAbout,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help),
            title: Text(AppLocalizations.of(context)!.helpCenter),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showHelp,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: Text(AppLocalizations.of(context)!.feedback),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _sendFeedback,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.star),
            title: Text(AppLocalizations.of(context)!.rateApp),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _rateApp,
          ),
        ],
      ),
    );
  }

  Future<void> _showColorPicker() async {
    final app_theme.ThemeNotifier themeNotifier =
        ref.read(themeNotifierProvider);
    // 从 Provider 获取初始颜色
    Color pickedColor = themeNotifier.primaryColor;
    // 保存页面的 context，以便在对话框关闭后使用
    final pageContext = context;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        // 【关键】使用 StatefulBuilder
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.selectThemeColor),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 颜色预览框
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: pickedColor, // <-- 这个颜色需要实时更新
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 自定义色调滑块 - 真正的颜色条拖动选择
                    _buildHueSlider(pickedColor, (Color color) {
                      dialogSetState(() {
                        pickedColor = color;
                      });
                    }),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(AppLocalizations.of(context)!.cancel),
                  onPressed: () {
                    if (dialogContext.canPop()) {
                      dialogContext.pop();
                    }
                  },
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context)!.ok),
                  onPressed: () {
                    // 这里保存的是被 dialogSetState 正确更新后的最新值
                    themeNotifier.setPrimaryColor(pickedColor);
                    if (dialogContext.canPop()) {
                      dialogContext.pop();
                    }
                    ScaffoldMessenger.of(pageContext).showSnackBar(
                      SnackBar(
                          content: Text(
                              AppLocalizations.of(pageContext)!.themeColorUpdated)),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorOption(String name, Color color, String value) {
    final app_theme.ThemeNotifier themeNotifier =
        ref.read(themeNotifierProvider);
    final bool isSelected = themeNotifier.primaryColor == color;

    return GestureDetector(
      onTap: () {
        setState(() {
          _themeColor = name;
        });
        themeNotifier.setPrimaryColor(color);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('主题颜色已切换为 $name')),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectLanguage),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildLanguageOption('中文', '中文'),
              _buildLanguageOption('English', 'English'),
              _buildLanguageOption('日本語', '日本語'),
              _buildLanguageOption('한국어', '한국어'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String name, String value) {
    return ListTile(
      title: Text(name),
      trailing: _language == name ? const Icon(Icons.check, size: 20) : null,
      onTap: () {
        _applyLanguageSetting(name);
        Navigator.pop(context);
      },
    );
  }

  void _applyLanguageSetting(String language) {
    setState(() {
      _language = language;
    });

    Locale newLocale;
    switch (language) {
      case '中文':
        newLocale = const Locale('zh', 'CN');
        break;
      case 'English':
        newLocale = const Locale('en', 'US');
        break;
      case '日本語':
        newLocale = const Locale('ja', 'JP');
        break;
      case '한국어':
        newLocale = const Locale('ko', 'KR');
        break;
      default:
        newLocale = const Locale('zh', 'CN');
    }

    // 保存到持久化存储
    HiveService.saveSetting(AppConstants.languageSetting, language);
    HiveService.saveSetting(AppConstants.localeSetting, newLocale.toString());

    // 通知应用更新语言
    ref.read(localeNotifierProvider.notifier).setLocale(newLocale);

    // 显示成功消息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('语言已切换为 $language')),
    );
  }

  void _backupData() {
    // TODO: 实现数据备份
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context)!.backupInDevelopment)),
    );
  }

  void _restoreData() {
    // TODO: 实现数据恢复
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context)!.restoreInDevelopment)),
    );
  }

  void _clearData() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.clearData),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.clearDataConfirmation),
            const SizedBox(height: 16),
            Text(
              '请选择要清除的数据类型：',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => _showClearOptions(),
            child: const Text('下一步'),
          ),
        ],
      ),
    );
  }

  void _showClearOptions() {
    Navigator.pop(context); // 关闭确认对话框
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('选择清除类型'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildClearOption(
                icon: Icons.smart_toy,
                title: '仅清除AI数据',
                description: '清除AI配置、提示词和聊天记录，保留日程和设置',
                onTap: () => _clearAIData(),
              ),
              const Divider(height: 16),
              _buildClearOption(
                icon: Icons.task,
                title: '清除任务数据',
                description: '清除所有日程任务，保留分类、设置和AI配置',
                onTap: () => _clearTaskData(),
              ),
              const Divider(height: 16),
              _buildClearOption(
                icon: Icons.category,
                title: '清除自定义分类',
                description: '清除用户创建的分类，保留默认分类',
                onTap: () => _clearUserCategories(),
              ),
              const Divider(height: 16),
              _buildClearOption(
                icon: Icons.settings,
                title: '清除应用设置',
                description: '清除主题、语言等设置，保留数据和AI配置',
                onTap: () => _clearAppSettings(),
              ),
              const Divider(height: 16),
              _buildClearOption(
                icon: Icons.cached,
                title: '清除缓存',
                description: '清除临时缓存数据，不影响其他数据',
                onTap: () => _clearCacheData(),
              ),
              const Divider(height: 16),
              _buildClearOption(
                icon: Icons.delete_forever,
                title: '清除所有数据',
                description: '完全重置应用，删除所有数据',
                onTap: () => _clearAllData(),
                isDanger: true,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildClearOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? Colors.red : null),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        description,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _clearAIData() async {
    Navigator.pop(context); // 关闭选项对话框
    final result = await _showConfirmDialog('清除AI数据', '确定要清除所有AI配置、提示词和聊天记录吗？');
    if (result) {
      // 1. 调用修复后的清除服务
      await HiveService.clearAIData(ref);

      // 2. **最关键的一步**: 让AI配置Provider失效并强制重建。
      //    重建时，它会从Hive中读取（此时已为空），从而获得正确的初始状态。
      ref.invalidate(aiConfigProvider);

      // 3. 显示成功提示
      _showSuccessMessage('AI设置已成功清除并重置');
    }
  }

  Future<void> _clearTaskData() async {
    Navigator.pop(context);
    final result = await _showConfirmDialog('清除任务数据', '确定要清除所有日程任务吗？此操作不可撤销。');
    if (result) {
      await HiveService.clearTaskData();

      // 强制刷新任务相关的Provider
      ref.invalidate(tasksProvider);
      ref.invalidate(selectedDateProvider);

      _showSuccessMessage('任务数据已清除');
    }
  }

  Future<void> _clearUserCategories() async {
    Navigator.pop(context);
    final result =
        await _showConfirmDialog('清除自定义分类', '确定要清除所有用户创建的分类吗？默认分类将保留。');
    if (result) {
      await HiveService.clearUserCategories();
      _showSuccessMessage('自定义分类已清除');
    }
  }

  Future<void> _clearAppSettings() async {
    Navigator.pop(context);
    final result = await _showConfirmDialog('清除应用设置', '确定要清除所有应用设置吗？AI配置将保留。');
    if (result) {
      await HiveService.clearAppSettings();
      _showSuccessMessage('应用设置已清除');
    }
  }

  Future<void> _clearCacheData() async {
    Navigator.pop(context);
    final result = await _showConfirmDialog('清除缓存', '确定要清除所有缓存数据吗？');
    if (result) {
      await HiveService.clearCacheData();
      _showSuccessMessage('缓存已清除');
    }
  }

  Future<void> _clearAllData() async {
    Navigator.pop(context);
    final result =
        await _showConfirmDialog('清除所有数据', '确定要完全重置应用吗？所有数据将被删除，此操作不可撤销！');
    if (result) {
      await HiveService.clearAllData(ref);
      _showSuccessMessage('所有数据已清除，应用已重置');
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('关于 AI Smart Calendar'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('版本: 1.0.0'),
              SizedBox(height: 8),
              Text('AI Smart Calendar 是一个智能日程管理应用，帮助您高效规划时间和管理任务。'),
              SizedBox(height: 16),
              Text('主要功能:'),
              Text('• AI 智能任务建议'),
              Text('• 多视图日历'),
              Text('• 智能提醒'),
              Text('• 数据同步'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    // TODO: 显示帮助中心
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.helpInDevelopment)),
    );
  }

  void _sendFeedback() {
    // TODO: 发送反馈
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context)!.feedbackInDevelopment)),
    );
  }

  void _rateApp() {
    // TODO: 跳转到应用商店评分
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.rateInDevelopment)),
    );
  }

  // 自定义色调滑块组件
  Widget _buildHueSlider(
      Color currentColor, ValueChanged<Color> onColorChanged) {
    // 获取当前颜色的色调值
    final HSVColor hsvColor = HSVColor.fromColor(currentColor);
    double hue = hsvColor.hue;

    return Container(
      width: 300, // 固定宽度，避免布局约束问题
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF0000), // 红
            Color(0xFFFFFF00), // 黄
            Color(0xFF00FF00), // 绿
            Color(0xFF00FFFF), // 青
            Color(0xFF0000FF), // 蓝
            Color(0xFFFF00FF), // 紫
            Color(0xFFFF0000), // 红（回到起点）
          ],
          stops: [0.0, 0.17, 0.33, 0.5, 0.67, 0.83, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: (details) {
                _handleColorSelection(
                    details.localPosition.dx, 300, onColorChanged);
              },
              onPanDown: (details) {
                _handleColorSelection(
                    details.localPosition.dx, 300, onColorChanged);
              },
              onTapDown: (details) {
                _handleColorSelection(
                    details.localPosition.dx, 300, onColorChanged);
              },
            ),
          ),
          // 滑块指示器
          Positioned(
            left: (hue / 360.0) * 300 - 8, // 基于固定宽度计算
            top: 0,
            bottom: 0,
            child: Container(
              width: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleColorSelection(
      double localX, double sliderWidth, ValueChanged<Color> onColorChanged) {
    // 确保触摸位置在滑块范围内
    final double clampedX = localX.clamp(0.0, sliderWidth);

    // 计算色调值 (0-360)
    final double newHue = (clampedX / sliderWidth) * 360.0;

    // 创建新的 HSV 颜色，固定饱和度和亮度
    final HSVColor newHsvColor = HSVColor.fromAHSV(
      1.0,
      newHue,
      1.0, // 固定饱和度
      0.8, // 固定亮度
    );

    onColorChanged(newHsvColor.toColor());
  }
}
