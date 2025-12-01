import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_smart_calendar/dao/theme.dart';
import 'package:ai_smart_calendar/theme/app_theme.dart' as app_theme;

class MockBuildContext extends Fake implements BuildContext {}

class MockThemeNotifier extends app_theme.ThemeNotifier {
  Color testColor = const Color(0xFF2196F3); // 默认蓝色

  @override
  Color get primaryColor => testColor;

  @override
  ThemeMode get mode => ThemeMode.light;

  @override
  void setPrimaryColor(Color color) {
    testColor = color;
  }
}

void main() {
  group('ThemeDao', () {
    test('colorSchema generates ThemeData with seed color', () {
      // 设置测试颜色
      final MockThemeNotifier mockNotifier = MockThemeNotifier();
      mockNotifier.testColor = const Color(0xFFE91E63); // 粉色

      // 创建一个 Mock BuildContext
      final BuildContext mockContext = MockBuildContext();

      // 生成亮色主题
      final ThemeData lightTheme =
          ThemeDao.colorSchema(mockNotifier, mockContext, Brightness.light);

      // 验证主题数据已生成
      expect(lightTheme, isNotNull);
      // 验证主题使用了正确的亮度模式
      expect(lightTheme.brightness, equals(Brightness.light));

      // 生成暗色主题
      final ThemeData darkTheme =
          ThemeDao.colorSchema(mockNotifier, mockContext, Brightness.dark);

      // 验证主题数据已生成
      expect(darkTheme, isNotNull);
      // 验证主题使用了正确的亮度模式
      expect(darkTheme.brightness, equals(Brightness.dark));
    });
  });
}
