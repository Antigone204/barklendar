import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/pages/adaptive_home.dart';
import 'package:ai_smart_calendar/pages/todo_detail_page.dart';
import 'package:ai_smart_calendar/pages/ai_page.dart';
import 'package:ai_smart_calendar/pages/settings_page.dart';
import 'package:ai_smart_calendar/pages/ai_settings_page.dart';
import 'package:ai_smart_calendar/pages/ai_config_list_page.dart';
import 'package:ai_smart_calendar/pages/ai_config_form_page.dart';
import 'package:ai_smart_calendar/pages/ai_service_detail_page.dart';

/// 应用的路由配置
final GoRouter router = GoRouter(
  // 1. 应用启动时首先显示的路径
  initialLocation: '/',

  // 2. 定义所有路由规则
  routes: <RouteBase>[
    // 主页
    GoRoute(
      name: 'home',
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const AdaptiveHome();
      },
    ),

// 新增任务页 —— 明确 extra 为 null
    GoRoute(
      name: 'add_task',
      path: '/add-task',
      builder: (context, state) {
        // 新增时根本不会传 extra，直接写 null 最清晰
        return TodoDetailPage(
          taskId: null,
          initialTask: null, // 明确是新增
        );
      },
    ),
    // 编辑任务页
    GoRoute(
      name: 'task_detail',
      path: '/task/:taskId',
      builder: (BuildContext context, GoRouterState state) {
        final taskId = state.pathParameters['taskId'];
        final task = state.extra as TaskModel?; // 直接传整个对象！
        return TodoDetailPage(
          taskId: taskId,
          initialTask: task, // 不为 null = 编辑
        );
      },
    ),

    // AI 交互页
    GoRoute(
      name: 'ai',
      path: '/ai',
      builder: (BuildContext context, GoRouterState state) {
        return const AIPage();
      },
    ),

    // 设置页
    GoRoute(
      name: 'settings',
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsPage();
      },
    ),

    // AI 设置页
    GoRoute(
      name: 'ai_settings',
      path: '/ai-settings',
      builder: (BuildContext context, GoRouterState state) {
        return const AISettingsPage();
      },
    ),

    // AI 配置列表页
    GoRoute(
      name: 'ai_configs',
      path: '/ai-configs',
      builder: (BuildContext context, GoRouterState state) {
        return const AiConfigListPage();
      },
    ),

    // AI 配置表单页
    GoRoute(
      name: 'ai_config_form',
      path: '/ai-config-form',
      builder: (BuildContext context, GoRouterState state) {
        final config = state.extra as Map<String, String>?; // 直接传整个对象！
        return AiConfigFormPage(config: config);
      },
    ),

    // AI 服务详情页
    GoRoute(
      name: 'ai_service_detail',
      path: '/ai-service-detail',
      builder: (BuildContext context, GoRouterState state) {
        final config = state.extra as Map<String, String>?; // 直接传整个对象！
        return AiServiceDetailPage(config: config);
      },
    ),
  ],

  // 3. 错误处理（可选，但推荐）
  // 当找不到匹配的路由时，会显示这个页面
  errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
    appBar: AppBar(title: const Text('页面未找到')),
    body: Center(
      child: Text('错误: ${state.error}'),
    ),
  ),
);
