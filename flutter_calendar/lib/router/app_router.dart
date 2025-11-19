import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_smart_calendar/models/task_model.dart';
import 'package:ai_smart_calendar/pages/home_page.dart';
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
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomePage();
      },
    ),

    // 任务详情页
    // 注意路径中的 `:taskId`，这是一个路径参数
    GoRoute(
      path: '/task/:taskId',
      builder: (BuildContext context, GoRouterState state) {
        final String taskId = state.pathParameters['taskId']!;
        return TodoDetailPage(
          taskId: taskId,
          isEditing: true,
        );
      },
    ),

    // 添加任务页
    GoRoute(
      path: '/add-task',
      builder: (BuildContext context, GoRouterState state) {
        return const TodoDetailPage();
      },
    ),

    // AI 交互页
    GoRoute(
      path: '/ai',
      builder: (BuildContext context, GoRouterState state) {
        return const AIPage();
      },
    ),

    // 设置页
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsPage();
      },
    ),

    // AI 设置页
    GoRoute(
      path: '/ai-settings',
      builder: (BuildContext context, GoRouterState state) {
        return const AISettingsPage();
      },
    ),

    // AI 配置列表页
    GoRoute(
      path: '/ai-configs',
      builder: (BuildContext context, GoRouterState state) {
        return const AiConfigListPage();
      },
    ),

    // AI 配置表单页
    GoRoute(
      path: '/ai-config-form',
      builder: (BuildContext context, GoRouterState state) {
        final config = state.extra as Map<String, String>?;
        return AiConfigFormPage(config: config);
      },
    ),

    // AI 服务详情页
    GoRoute(
      path: '/ai-service-detail',
      builder: (BuildContext context, GoRouterState state) {
        final config = state.extra as Map<String, String>?;
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
