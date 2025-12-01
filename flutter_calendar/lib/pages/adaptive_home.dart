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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final List<ConsumerStatefulWidget> pages = <ConsumerStatefulWidget>[
      const CalendarPage(key: ValueKey('calendar')),
      const TaskListPage(key: ValueKey('task_list')),
      const AIPage(key: ValueKey('ai')),
      const SettingsPage(key: ValueKey('settings')),
    ];

    final List<NavigationDestination> destinations = <NavigationDestination>[
      NavigationDestination(
          icon: const Icon(Icons.calendar_today), label: l10n.calendar,),
      NavigationDestination(icon: const Icon(Icons.list), label: l10n.tasks),
      NavigationDestination(
          icon: const Icon(Icons.auto_awesome), label: l10n.ai,),
      NavigationDestination(
          icon: const Icon(Icons.settings), label: l10n.settings,),
    ];

    return Scaffold(
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final Object? result = await context.toTaskDetail();
                if (result is TaskModel && mounted) {
                  ref.read(tasksProvider.notifier).addTask(result);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: AdaptiveLayout(
        // 已删除报错的 primaryNavigationWidth 参数

        // 底部导航：小屏显示
        bottomNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig?>{
            Breakpoints.small: SlotLayout.from(
              key: const Key('bottom'),
              builder: (_) => BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onDestinationSelected,
                type: BottomNavigationBarType.fixed,
                items: destinations
                    .map((NavigationDestination d) =>
                        BottomNavigationBarItem(icon: d.icon, label: d.label),)
                    .toList(),
              ),
            ),
          },
        ),

        // 侧边导航：中大屏显示
        primaryNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig?>{
            Breakpoints.mediumAndUp: SlotLayout.from(
              key: const Key('rail'),
              // 【关键修复】：在这里用 SizedBox 限制宽度
              builder: (_) => SizedBox(
                width: 80, // 强制宽度为 80，防止占满半屏
                child: NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  // 让 NavigationRail 自身也紧凑一点（可选）
                  minWidth: 72,
                  destinations: destinations
                      .map(AdaptiveScaffold.toRailDestination)
                      .toList(),
                ),
              ),
            ),
          },
        ),

        // 核心内容区域
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig?>{
            Breakpoints.standard: SlotLayout.from(
              key: const Key('body'),
              builder: (_) => IndexedStack(
                index: _selectedIndex,
                children: pages,
              ),
            ),
          },
        ),
      ),
    );
  }
}
