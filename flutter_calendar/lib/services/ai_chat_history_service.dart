import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AIChatHistoryService {
  static const String chatHistoryFileName = 'ai_chat_history.json';

  static Future<Directory> getCacheDir() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory cacheDir = Directory('${appDocDir.path}/ai_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// 保存聊天历史
  static Future<void> saveChatHistory(
    List<Map<String, dynamic>> messages,
  ) async {
    try {
      final Directory cacheDir = await getCacheDir();
      final File file = File('${cacheDir.path}/$chatHistoryFileName');

      // 只保存最新的100条消息
      List<Map<String, dynamic>> messagesToSave = messages;
      if (messages.length > 100) {
        messagesToSave = messages.sublist(0, 100);
      }

      final Map<String, Object> data = <String, Object>{
        'messages': messagesToSave,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await file.writeAsString(json.encode(data));
      debugPrint('聊天历史已保存: ${messagesToSave.length} 条消息');
    } catch (e) {
      // 静默处理错误，不影响主流程
      debugPrint('保存聊天历史失败: $e');
    }
  }

  /// 加载聊天历史
  static Future<List<Map<String, dynamic>>> loadChatHistory() async {
    try {
      final Directory cacheDir = await getCacheDir();
      final File file = File('${cacheDir.path}/$chatHistoryFileName');

      if (await file.exists()) {
        final String content = await file.readAsString();
        final Map<String, dynamic> data =
            json.decode(content) as Map<String, dynamic>;

        // 检查时间戳，如果超过7天则不加载
        final int? timestamp = data['timestamp'] as int?;
        if (timestamp != null) {
          final DateTime savedTime =
              DateTime.fromMillisecondsSinceEpoch(timestamp);
          final DateTime now = DateTime.now();
          if (now.difference(savedTime).inDays > 7) {
            // 超过7天，清除文件
            await file.delete();
            return <Map<String, dynamic>>[];
          }
        }

        final List<dynamic>? messageList = data['messages'] as List<dynamic>?;

        return messageList
                ?.map((item) => item as Map<String, dynamic>)
                .toList() ??
            <Map<String, dynamic>>[];
      }
    } catch (e) {
      // 静默处理错误，返回空列表
      debugPrint('加载聊天历史失败: $e');
    }
    return <Map<String, dynamic>>[];
  }

  /// 清除聊天历史
  static Future<void> clearChatHistory() async {
    try {
      final Directory cacheDir = await getCacheDir();
      final File file = File('${cacheDir.path}/$chatHistoryFileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // 静默处理错误
      debugPrint('清除聊天历史失败: $e');
    }
  }
}
