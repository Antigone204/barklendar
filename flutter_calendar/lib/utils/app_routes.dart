/// 应用路由常量
class AppRoutes {
  static const String home = '/';
  // 任务详情页路由
  // 使用 go_router 的命名路由进行跳转：
  // - 'add_task' 用于新增任务
  // - 'task_detail' 用于编辑任务
  // 推荐使用 route_utils.dart 中的 toTaskDetail() 扩展方法
  static const String taskDetail = '/task/:taskId';
  static const String addTask = '/add-task';
  static const String ai = '/ai';
  static const String settings = '/settings';
  static const String aiSettings = '/ai-settings';
  static const String aiConfigs = '/ai-configs';
  static const String aiConfigForm = '/ai-config-form';
  static const String aiServiceDetail = '/ai-service-detail';
}
