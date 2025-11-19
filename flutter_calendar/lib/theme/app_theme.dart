// app_theme.dart
// Flutter 主题封装：light / dark 两套 ThemeData，动态 TextTheme，
// 修正 CardTheme，提供 ThemeMode 持久化管理示例（使用 shared_preferences）。
// 使用说明：在 pubspec.yaml 中添加依赖：
//   shared_preferences: ^2.0.0

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题类：集中管理颜色、样式，并提供 lightTheme / darkTheme。
/// 同时提供 ThemeNotifier 用于运行时切换并持久化 ThemeMode。
class AppTheme {
  // -------------------- 基础颜色常量（作为设计参考 / 种子色）
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryColorDark = Color(0xFF1976D2);
  static const Color primaryColorLight = Color(0xFFBBDEFB);

  static const Color accentColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);

  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // 分割线、阴影的参考值
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color shadowColor = Color(0x1F000000);

  // -------------------- 生成 ThemeData（基于 ColorScheme）

  static ThemeData get lightTheme {
    final ColorScheme cs = ColorScheme.fromSeed(seedColor: primaryColor);
    return _buildLightTheme(cs);
  }

  static ThemeData get darkTheme {
    final ColorScheme cs = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );
    return _buildDarkTheme(cs);
  }

  // 基于动态颜色的主题生成方法
  static ThemeData buildLightTheme(Color primaryColor) {
    final ColorScheme cs = ColorScheme.fromSeed(seedColor: primaryColor);
    return _buildLightTheme(cs);
  }

  static ThemeData buildDarkTheme(Color primaryColor) {
    final ColorScheme cs = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );
    return _buildDarkTheme(cs);
  }

  static ThemeData _buildLightTheme(ColorScheme cs) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      // scaffold 背景、AppBar 等尽量使用 colorScheme 的值，保持一致性
      scaffoldBackgroundColor: Colors.white, // 保持白色背景
      appBarTheme: AppBarTheme(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        centerTitle: true,
      ),
      // CardTheme: 修正为 CardThemeData
      cardTheme: CardThemeData(
        color: Colors.white, // 保持白色卡片
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white, // 保持白色输入框背景
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
      dividerColor: cs.outline,
      // textTheme 使用 colorScheme.onBackground，确保亮/暗模式可读性
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: cs.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: cs.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: cs.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: cs.outline,
        ),
      ),
      // 底部导航栏示例
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white, // 保持白色底部导航栏
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withOpacity(0.6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.white, // 保持白色SnackBar
        contentTextStyle: TextStyle(color: cs.onSurface),
      ),
    );
  }

  static ThemeData _buildDarkTheme(ColorScheme cs) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF121212), // 深色背景
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: cs.onPrimary,
        elevation: 2,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2D2D2D),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
      dividerColor: cs.outline,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: cs.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: cs.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: cs.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: cs.outline,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withOpacity(0.6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2D2D2D),
        contentTextStyle: TextStyle(color: cs.onSurface),
      ),
    );
  }
}

// -------------------- 运行时主题管理（持久化）示例 --------------------

/// ThemeNotifier 管理 ThemeMode 和主题颜色，并把选择持久化到 SharedPreferences。
class ThemeNotifier extends ChangeNotifier {
  static const String _prefsKey = 'app_theme_mode';
  static const String _prefsColorKey = 'app_theme_color';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Color _primaryColor = AppTheme.primaryColor;
  Color get primaryColor => _primaryColor;

  // 【新增】添加一个测试开关
  bool _useFlexColorScheme = true;
  bool get useFlexColorScheme => _useFlexColorScheme;

  ThemeNotifier() {
    _loadFromPrefs();
  }

  void setMode(ThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    _saveToPrefs();
  }

  void toggleLightDark() {
    if (_mode == ThemeMode.dark) {
      setMode(ThemeMode.light);
    } else {
      setMode(ThemeMode.dark);
    }
  }

  void setPrimaryColor(Color color) {
    if (color == _primaryColor) return;
    _primaryColor = color;
    notifyListeners();
    _saveColorToPrefs();
  }

  // 【新增】一个方法来切换开关
  void toggleThemeEngine() {
    _useFlexColorScheme = !_useFlexColorScheme;
    debugPrint(
        '--- Switched Theme Engine: useFlexColorScheme is now $_useFlexColorScheme ---');
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // 加载主题模式
      final String stored = prefs.getString(_prefsKey) ?? 'system';
      final ThemeMode newMode;
      switch (stored) {
        case 'light':
          newMode = ThemeMode.light;
          break;
        case 'dark':
          newMode = ThemeMode.dark;
          break;
        default:
          newMode = ThemeMode.system;
      }

      // 加载主题颜色 - 优先使用新的整数值存储方式
      Color newColor = AppTheme.primaryColor; // 默认颜色
      final int? storedColorValue = prefs.getInt(_prefsColorKey);
      if (storedColorValue != null) {
        // 使用新的整数值存储方式
        newColor = Color(storedColorValue);
      } else {
        // 向后兼容：尝试使用旧的字符串存储方式
        final String storedColor = prefs.getString(_prefsColorKey) ?? 'blue';
        newColor = _getColorFromString(storedColor);
      }

      // 只有在模式或颜色实际发生变化时才通知监听器
      bool shouldNotify = false;
      if (_mode != newMode) {
        _mode = newMode;
        shouldNotify = true;
      }
      if (_primaryColor != newColor) {
        _primaryColor = newColor;
        shouldNotify = true;
      }

      if (shouldNotify) {
        notifyListeners();
      }
    } catch (_) {
      // ignore errors and keep system as default
      if (_mode != ThemeMode.system) {
        _mode = ThemeMode.system;
        notifyListeners();
      }
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String value = _mode == ThemeMode.light
          ? 'light'
          : _mode == ThemeMode.dark
              ? 'dark'
              : 'system';
      await prefs.setString(_prefsKey, value);
    } catch (_) {
      // 忽略存储错误
    }
  }

  Future<void> _saveColorToPrefs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // 存储颜色的整数值，支持所有颜色类型
      await prefs.setInt(_prefsColorKey, _primaryColor.value);
    } catch (_) {
      // 忽略存储错误
    }
  }

  Color _getColorFromString(String colorString) {
    // 为了向后兼容，仍然支持旧的字符串格式
    switch (colorString) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'blueAccent':
        return Colors.blueAccent;
      case 'cyan':
        return Colors.cyan;
      case 'red':
        return Colors.red;
      default:
        return Colors.blue; // 默认颜色
    }
  }
}
