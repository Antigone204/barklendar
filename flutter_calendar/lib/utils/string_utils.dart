import 'dart:math';
import 'package:flutter/material.dart';

class StringUtils {
  // 检查字符串是否为空或null
  static bool isNullOrEmpty(String? value) {
    return value == null || value.isEmpty;
  }

  // 检查字符串是否不为空
  static bool isNotNullOrEmpty(String? value) {
    return value != null && value.isNotEmpty;
  }

  // 截断字符串并添加省略号
  static String truncateWithEllipsis(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // 移除字符串中的所有空格
  static String removeAllWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), '');
  }

  // 将字符串转换为标题格式（每个单词首字母大写）
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;

    return text
        .toLowerCase()
        .split(' ')
        .map(
          (String word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }

  // 将字符串转换为驼峰命名法
  static String toCamelCase(String text) {
    if (text.isEmpty) return text;

    final List<String> words = text.toLowerCase().split(RegExp(r'[_\s]+'));
    if (words.isEmpty) return text;

    final String firstWord = words[0];
    final Iterable<String> remainingWords = words.sublist(1).map(
          (String word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        );

    return firstWord + remainingWords.join();
  }

  // 将字符串转换为蛇形命名法
  static String toSnakeCase(String text) {
    return text
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (Match match) => '_${match.group(0)}',
        )
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  // 提取字符串中的数字
  static String extractNumbers(String text) {
    return text.replaceAll(RegExp(r'[^0-9]'), '');
  }

  // 提取字符串中的字母
  static String extractLetters(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z]'), '');
  }

  // 检查字符串是否包含中文
  static bool containsChinese(String text) {
    return RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
  }

  // 检查字符串是否包含数字
  static bool containsNumbers(String text) {
    return RegExp(r'[0-9]').hasMatch(text);
  }

  // 检查字符串是否包含字母
  static bool containsLetters(String text) {
    return RegExp(r'[a-zA-Z]').hasMatch(text);
  }

  // 检查字符串是否包含特殊字符
  static bool containsSpecialCharacters(String text) {
    return RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(text);
  }

  // 检查字符串是否为有效的电子邮件地址
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    ).hasMatch(email);
  }

  // 检查字符串是否为有效的手机号码（中国）
  static bool isValidChinesePhoneNumber(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }

  // 检查字符串是否为有效的URL
  static bool isValidUrl(String url) {
    return RegExp(
      r'^(https?://)?([\da-z.-]+)\.([a-z.]{2,6})([/\w .-]*)*/?$',
    ).hasMatch(url);
  }

  // 隐藏手机号码中间四位
  static String maskPhoneNumber(String phone) {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }

  // 隐藏电子邮件地址的部分内容
  static String maskEmail(String email) {
    final List<String> parts = email.split('@');
    if (parts.length != 2) return email;

    final String username = parts[0];
    final String domain = parts[1];

    if (username.length <= 2) {
      return '${username[0]}***@$domain';
    } else {
      return '${username.substring(0, 2)}***@$domain';
    }
  }

  // 计算字符串的字符数（中文算1个字符，英文算0.5个字符）
  static double calculateTextLength(String text) {
    double length = 0;
    for (final int rune in text.runes) {
      // 中文字符范围
      if (rune >= 0x4E00 && rune <= 0x9FFF) {
        length += 1;
      } else {
        length += 0.5;
      }
    }
    return length;
  }

  // 根据字符数限制截断文本
  static String truncateByTextLength(String text, double maxLength) {
    double currentLength = 0;
    int index = 0;

    for (final int rune in text.runes) {
      final num charLength = (rune >= 0x4E00 && rune <= 0x9FFF) ? 1 : 0.5;
      if (currentLength + charLength > maxLength) {
        break;
      }
      currentLength += charLength;
      index += String.fromCharCode(rune).length;
    }

    if (index >= text.length) return text;
    return '${text.substring(0, index)}...';
  }

  // 将字节数转换为可读的文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // 将数字转换为中文数字
  static String toChineseNumber(int number) {
    const List<String> chineseNumbers = <String>[
      '零',
      '一',
      '二',
      '三',
      '四',
      '五',
      '六',
      '七',
      '八',
      '九',
    ];
    const List<String> chineseUnits = <String>['', '十', '百', '千', '万'];

    if (number == 0) return chineseNumbers[0];

    String result = '';
    final String numStr = number.toString();
    final int length = numStr.length;

    for (int i = 0; i < length; i++) {
      final int digit = int.parse(numStr[i]);
      final int unitIndex = length - i - 1;

      if (digit != 0) {
        result += chineseNumbers[digit] + chineseUnits[unitIndex];
      } else if (i > 0 && int.parse(numStr[i - 1]) != 0) {
        result += chineseNumbers[digit];
      }
    }

    // 处理特殊情况
    if (result.startsWith('一十')) {
      result = result.substring(1);
    }

    return result.replaceAll(RegExp(r'零+'), '零').replaceAll(RegExp(r'零$'), '');
  }

  // 生成随机字符串
  static String generateRandomString(int length) {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // 计算字符串的相似度（0-1之间）
  static double calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final String longer = s1.length > s2.length ? s1 : s2;
    final String shorter = s1.length > s2.length ? s2 : s1;

    // 计算编辑距离
    final List<int> costs =
        List.generate(shorter.length + 1, (int index) => index);

    for (int i = 1; i <= longer.length; i++) {
      int previousValue = i - 1;
      int cost = i;

      for (int j = 1; j <= shorter.length; j++) {
        if (longer[i - 1] == shorter[j - 1]) {
          cost = costs[j - 1];
        } else {
          cost = 1 +
              <int>[costs[j - 1], costs[j], previousValue]
                  .reduce((int a, int b) => a < b ? a : b);
        }
        previousValue = costs[j];
        costs[j] = cost;
      }
    }

    final int maxLength = longer.length;
    if (maxLength == 0) return 1.0;

    return (maxLength - costs[shorter.length]) / maxLength;
  }

  // 提取字符串中的关键词
  static List<String> extractKeywords(String text, {int minLength = 2}) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^\w\u4e00-\u9fff]+'))
        .where((String word) => word.length >= minLength)
        .toSet()
        .toList();
  }

  // 计算文本的阅读时间（以分钟计）
  static int calculateReadingTime(String text, {int wordsPerMinute = 200}) {
    final int wordCount = text.split(RegExp(r'\s+')).length;
    return (wordCount / wordsPerMinute).ceil();
  }

  // 将字符串转换为颜色
  static Color stringToColor(String text) {
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return Color.fromARGB(
      255,
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      hash & 0x0000FF,
    );
  }

  // 检查字符串是否为回文
  static bool isPalindrome(String text) {
    final String cleanText =
        text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]'), '');
    return cleanText == cleanText.split('').reversed.join();
  }

  // 将字符串按行分割并去除空行
  static List<String> splitLines(String text) {
    return text
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList();
  }

  // 将字符串列表连接为自然语言列表
  static String joinNaturalLanguage(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items[0];
    if (items.length == 2) return '${items[0]}和${items[1]}';

    return '${items.sublist(0, items.length - 1).join('、')}和${items.last}';
  }

  // 转义HTML特殊字符
  static String escapeHtml(String text) {
    return text
        .replaceAll('&', '&')
        .replaceAll('<', '<')
        .replaceAll('>', '>')
        .replaceAll('"', '"')
        .replaceAll("'", '&#39;');
  }

  // 反转义HTML特殊字符
  static String unescapeHtml(String text) {
    return text
        .replaceAll('&', '&')
        .replaceAll('<', '<')
        .replaceAll('>', '>')
        .replaceAll('"', '"')
        .replaceAll('&#39;', "'");
  }
}
