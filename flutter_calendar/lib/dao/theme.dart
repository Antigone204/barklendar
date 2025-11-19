import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_smart_calendar/theme/app_theme.dart' as app_theme;

class ThemeDao {
  // 模拟 prefsNotifier，实际项目中应该从外部传入
  static final ThemeNotifier prefsNotifier = ThemeNotifier();

  static ThemeData colorSchema(
    app_theme.ThemeNotifier prefsNotifier,
    BuildContext context,
    Brightness brightness,
  ) {
    final Color seedColor = prefsNotifier.primaryColor;

    // 根据开关决定使用哪种主题引擎
    if (prefsNotifier.useFlexColorScheme) {
      // --- 您的原始 FlexColorScheme 逻辑 ---
      debugPrint('--- Building Theme using FlexColorScheme ---');
      final ColorScheme colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      );
      return FlexThemeData.light(
        // Or .dark based on brightness
        colorScheme: colorScheme,
        useMaterial3: true,
      );
      // ... 确保亮暗模式分支正确
    } else {
      // --- 【关键】一个最纯粹、最原生的 Flutter 主题逻辑 ---
      debugPrint('--- Building Theme using NATIVE ThemeData ---');
      final ColorScheme colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      );
      // 直接使用 ThemeData.from，不经过任何第三方库
      return ThemeData.from(colorScheme: colorScheme, useMaterial3: true);
    }
  }
}

// 模拟 ThemeNotifier 类，实际项目中应该从外部导入
class ThemeNotifier {
  int themeColor = 0xFF2196F3; // 默认蓝色
  bool trueDarkMode = false; // 默认不使用纯黑模式

  // 模拟从 SharedPreferences 加载颜色
  Future<void> loadColorFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? storedColorValue = prefs.getInt('app_theme_color');
    if (storedColorValue != null) {
      themeColor = storedColorValue;
    }

    // 加载深色模式设置
    final bool? storedDarkMode = prefs.getBool('app_true_dark_mode');
    if (storedDarkMode != null) {
      trueDarkMode = storedDarkMode;
    }
  }
}
