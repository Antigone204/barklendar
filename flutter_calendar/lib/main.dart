// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ai_smart_calendar/theme/app_theme.dart' as app_theme;
import 'package:ai_smart_calendar/services/hive_service.dart';
import 'package:ai_smart_calendar/services/notification_service.dart';
import 'package:ai_smart_calendar/router/app_router.dart';
import 'package:ai_smart_calendar/dao/theme.dart';
import 'package:ai_smart_calendar/services/lifecycle_manager.dart';
import 'package:ai_smart_calendar/l10n/app_localizations.dart';
import 'package:ai_smart_calendar/providers/locale_provider.dart';

// 主题 Provider 保持不变
final themeNotifierProvider =
    ChangeNotifierProvider<app_theme.ThemeNotifier>((ref) {
  return app_theme.ThemeNotifier();
});

void main() async {
  debugPrint('main() started');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('WidgetsFlutterBinding ensured');

  try {
    // 初始化流程保持简单
    await HiveService.init();
    debugPrint('Hive initialized successfully');
    await NotificationService.initialize();
    debugPrint('Notification service initialized');

    // **核心修改**: 我们用一个 AppInitializer 来包裹 MyApp
    runApp(
      const ProviderScope(
        child: AppInitializer(child: MyApp()),
      ),
    );
  } catch (e) {
    debugPrint('应用启动时发生致命错误: $e');
    runApp(InitializationErrorApp(error: e.toString()));
  }
  debugPrint('main() completed');
}

// **核心修改**: 创建这个新的 Widget 来安全地触发初始化
class AppInitializer extends ConsumerStatefulWidget {
  final Widget child;
  const AppInitializer({super.key, required this.child});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // 使用 Future.microtask 可以确保这个回调在首帧绘制完成后执行
    // 这是在 initState 中安全触发副作用的标准做法
    Future.microtask(() {
      debugPrint(
          "AppInitializer: Triggering startup processing after first frame.");
      // 我们只读取 Provider 来获取实例，然后调用方法
      ref.read(lifecycleManagerProvider).processTaskNotificationsOnStartup();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// MyApp 现在完全是"纯净"的，只负责UI
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // MyApp 中不再有任何对 lifecycleManagerProvider 的引用
    final themeNotifier = ref.watch(themeNotifierProvider);
    final currentLocale = ref.watch(localeNotifierProvider);
    final lightTheme =
        ThemeDao.colorSchema(themeNotifier, context, Brightness.light);
    final darkTheme =
        ThemeDao.colorSchema(themeNotifier, context, Brightness.dark);

    return MaterialApp.router(
      key: ValueKey(
          '${themeNotifier.primaryColor.value}_${currentLocale.languageCode}'),
      title: 'AI Smart Calendar',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeNotifier.mode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: currentLocale,
    );
  }
}

// 错误页面 Widget 保持不变
class InitializationErrorApp extends StatelessWidget {
  final String error;
  const InitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '应用无法启动。\n错误: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
