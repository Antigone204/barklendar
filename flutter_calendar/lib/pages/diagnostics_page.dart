import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_smart_calendar/theme/app_theme.dart';
import 'package:ai_smart_calendar/main.dart' show themeNotifierProvider;

class DiagnosticsPage extends ConsumerWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Diagnostics'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'This container color comes from Theme.of(context).primaryColor:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              color: Theme.of(context).primaryColor,
              child: Center(
                child: Text(
                  'Primary',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 添加颜色选择按钮
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildColorButton(ref, Colors.red, 'Red'),
                _buildColorButton(ref, Colors.blue, 'Blue'),
                _buildColorButton(ref, Colors.green, 'Green'),
                _buildColorButton(ref, Colors.orange, 'Orange'),
                _buildColorButton(ref, Colors.purple, 'Purple'),
                _buildColorButton(ref, Colors.pink, 'Pink'),
                _buildColorButton(ref, Colors.teal, 'Teal'),
                _buildColorButton(ref, Colors.indigo, 'Indigo'),
                _buildColorButton(
                    ref, const Color(0xFFE91E63), 'Pink (E91E63)'),
                _buildColorButton(
                    ref, const Color(0xFF9C27B0), 'Purple (9C27B0)'),
                _buildColorButton(
                    ref, const Color(0xFF3F51B5), 'Indigo (3F51B5)'),
                _buildColorButton(
                    ref, const Color(0xFF2196F3), 'Blue (2196F3)'),
                _buildColorButton(
                    ref, const Color(0xFF00BCD4), 'Cyan (00BCD4)'),
                _buildColorButton(
                    ref, const Color(0xFF4CAF50), 'Green (4CAF50)'),
                _buildColorButton(
                    ref, const Color(0xFFFFC107), 'Amber (FFC107)'),
                _buildColorButton(
                    ref, const Color(0xFFFF9800), 'Orange (FF9800)'),
                _buildColorButton(
                    ref, const Color(0xFF795548), 'Brown (795548)'),
                _buildColorButton(
                    ref, const Color(0xFF607D8B), 'Blue Grey (607D8B)'),
              ],
            ),

            const SizedBox(height: 20),

            // 【新增】切换主题引擎的按钮
            ElevatedButton(
              onPressed: () {
                ref.read(themeNotifierProvider.notifier).toggleThemeEngine();
              },
              child: const Text('Switch Theme Engine'),
            ),

            // 【新增】显示当前引擎状态的文本
            Text(
                'Current Engine: ${ref.watch(themeNotifierProvider).useFlexColorScheme ? "FlexColorScheme" : "Native"}'),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(WidgetRef ref, Color color, String label) {
    return ElevatedButton(
      onPressed: () {
        ref.read(themeNotifierProvider.notifier).setPrimaryColor(color);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor:
            color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        minimumSize: const Size(80, 40),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
