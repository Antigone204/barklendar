// lib/pages/adaptive_home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:ai_smart_calendar/pages/calendar_page.dart';
import 'package:ai_smart_calendar/pages/task_list_page.dart';
import 'package:ai_smart_calendar/pages/ai_page.dart';
import 'package:ai_smart_calendar/pages/settings_page.dart';
import 'package:ai_smart_calendar/l10n/app_localizations.dart';
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/utils/route_utils.dart';
import 'package:ai_smart_calendar/providers/tasks_provider.dart';

class AdaptiveHome extends ConsumerStatefulWidget {
  const AdaptiveHome({super.key});

  @override
  ConsumerState<AdaptiveHome> createState() => _AdaptiveHomeState();
}

class _AdaptiveHomeState extends ConsumerState<AdaptiveHome> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  // 构建浮动按钮 (FAB)
  Widget? _buildFab() {
    // 只在日历页(索引0)显示 FAB，如有需要可修改逻辑
    if (_selectedIndex != 0) return null;
    return FloatingActionButton(
      onPressed: () async {
        final result = await context.toTaskDetail();
        if (result is TaskModel && mounted) {
          ref.read(tasksProvider.notifier).addTask(result);
        }
      },
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 页面列表
    final pages = [
      const CalendarPage(key: ValueKey('calendar')),
      const TaskListPage(key: ValueKey('task_list')),
      const AIPage(key: ValueKey('ai')),
      const SettingsPage(key: ValueKey('settings')),
    ];

    // 导航项定义
    final destinations = [
      NavigationDestination(
          icon: const Icon(Icons.calendar_today), label: l10n.calendar),
      NavigationDestination(icon: const Icon(Icons.list), label: l10n.tasks),
      NavigationDestination(
          icon: const Icon(Icons.auto_awesome), label: l10n.ai),
      NavigationDestination(
          icon: const Icon(Icons.settings), label: l10n.settings),
    ];

    // 【修复关键】：这里添加了 Scaffold 包裹整个布局
    // 否则 AdaptiveLayout 没有 Material 画布，会导致黑屏
    return Scaffold(
      body: AdaptiveLayout(
        // 1. 底部导航：只在小屏 (Small) 显示
        bottomNavigation: SlotLayout(
          config: {
            Breakpoints.small: SlotLayout.from(
              key: const Key('bottom'),
              builder: (_) => BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onDestinationSelected,
                type: BottomNavigationBarType.fixed,
                items: destinations
                    .map((d) =>
                        BottomNavigationBarItem(icon: d.icon, label: d.label))
                    .toList(),
              ),
            ),
          },
        ),

        // 2. 左侧导航栏 (Rail)：中屏及以上 (MediumAndUp) 显示
        primaryNavigation: SlotLayout(
          config: {
            Breakpoints.mediumAndUp: SlotLayout.from(
              key: const Key('rail'),
              builder: (_) => NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                // groupAlignment: 0.0, // 可选：让图标垂直居中
                destinations: destinations
                    .map(AdaptiveScaffold.toRailDestination)
                    .toList(),
              ),
            ),
          },
        ),

        // 3. 主体内容 + FAB：所有尺寸都显示 (使用 Standard 兜底)
        body: SlotLayout(
          config: {
            Breakpoints.standard: SlotLayout.from(
              key: const Key('body'),
              builder: (_) {
                final fab = _buildFab();
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // 页面内容
                    IndexedStack(index: _selectedIndex, children: pages),

                    // 自定义位置的 FAB
                    if (fab != null)
                      Positioned(
                        right: 16,
                        // 适配底部安全区域 (如 iPhone 底部横条)
                        bottom: 16 + MediaQuery.of(context).padding.bottom,
                        child: fab,
                      ),
                  ],
                );
              },
            ),
          },
        ),

        // 4. 顶部 AppBar：所有尺寸都显示
        topNavigation: SlotLayout(
          config: {
            Breakpoints.standard: SlotLayout.from(
              key: const Key('appbar'),
              builder: (_) => AppBar(
                title: Text(l10n.aiSmartCalendar),
                elevation: 0,
                surfaceTintColor: Colors.transparent, // 去除滚动时的颜色覆盖
                automaticallyImplyLeading: false, // 去除默认返回箭头
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
            ),
          },
        ),
      ),
    );
  }
}
