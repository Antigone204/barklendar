import 'package:intl/intl.dart';

class DateUtils {
  // 格式化日期为中文格式
  static String formatChineseDate(DateTime date) {
    return DateFormat('yyyy年MM月dd日').format(date);
  }

  // 格式化时间为中文格式
  static String formatChineseTime(DateTime time) {
    return DateFormat('HH:mm:ss').format(time);
  }

  // 格式化日期时间为中文格式
  static String formatChineseDateTime(DateTime dateTime) {
    return DateFormat('yyyy年MM月dd日 HH:mm:ss').format(dateTime);
  }

  // 获取相对时间描述（如：刚刚、5分钟前、2小时前等）
  static String getRelativeTime(DateTime date) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      final int weeks = (difference.inDays / 7).floor();
      return '$weeks周前';
    } else if (difference.inDays < 365) {
      final int months = (difference.inDays / 30).floor();
      return '$months月前';
    } else {
      final int years = (difference.inDays / 365).floor();
      return '$years年前';
    }
  }

  // 检查是否为今天
  static bool isToday(DateTime date) {
    final DateTime now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // 检查两个日期是否为同一天
  static bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // 检查是否为明天
  static bool isTomorrow(DateTime date) {
    final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  // 检查是否为昨天
  static bool isYesterday(DateTime date) {
    final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // 检查是否为本周
  static bool isThisWeek(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // 检查是否为本月
  static bool isThisMonth(DateTime date) {
    final DateTime now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // 检查是否为今年
  static bool isThisYear(DateTime date) {
    return date.year == DateTime.now().year;
  }

  // 获取本周的开始日期（周一）
  static DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // 获取本周的结束日期（周日）
  static DateTime getEndOfWeek(DateTime date) {
    return date.add(Duration(days: DateTime.daysPerWeek - date.weekday));
  }

  // 获取本月的开始日期
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month);
  }

  // 获取本月的结束日期
  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // 获取本年的开始日期
  static DateTime getStartOfYear(DateTime date) {
    return DateTime(date.year);
  }

  // 获取本年的结束日期
  static DateTime getEndOfYear(DateTime date) {
    return DateTime(date.year, 12, 31);
  }

  // 计算两个日期之间的天数差
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  // 获取日期所在周的日期列表
  static List<DateTime> getWeekDates(DateTime date) {
    final DateTime startOfWeek = getStartOfWeek(date);
    return List.generate(
      7,
      (int index) => startOfWeek.add(Duration(days: index)),
    );
  }

  // 获取日期所在月的日期列表
  static List<DateTime> getMonthDates(DateTime date) {
    final DateTime startOfMonth = getStartOfMonth(date);
    final DateTime endOfMonth = getEndOfMonth(date);
    final int daysInMonth = endOfMonth.day;

    return List.generate(
      daysInMonth,
      (int index) => DateTime(startOfMonth.year, startOfMonth.month, index + 1),
    );
  }

  // 检查日期是否在范围内
  static bool isDateInRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }

  // 获取年龄
  static int getAge(DateTime birthDate) {
    final DateTime now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // 格式化持续时间
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}小时${duration.inMinutes.remainder(60)}分钟';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟${duration.inSeconds.remainder(60)}秒';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  // 获取工作日名称（中文）
  static String getChineseWeekday(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return '星期一';
      case DateTime.tuesday:
        return '星期二';
      case DateTime.wednesday:
        return '星期三';
      case DateTime.thursday:
        return '星期四';
      case DateTime.friday:
        return '星期五';
      case DateTime.saturday:
        return '星期六';
      case DateTime.sunday:
        return '星期日';
      default:
        return '';
    }
  }

  // 获取月份名称（中文）
  static String getChineseMonth(DateTime date) {
    switch (date.month) {
      case 1:
        return '一月';
      case 2:
        return '二月';
      case 3:
        return '三月';
      case 4:
        return '四月';
      case 5:
        return '五月';
      case 6:
        return '六月';
      case 7:
        return '七月';
      case 8:
        return '八月';
      case 9:
        return '九月';
      case 10:
        return '十月';
      case 11:
        return '十一月';
      case 12:
        return '十二月';
      default:
        return '';
    }
  }

  // 获取季度
  static int getQuarter(DateTime date) {
    return ((date.month - 1) / 3).floor() + 1;
  }

  // 检查是否为工作日（周一到周五）
  static bool isWorkday(DateTime date) {
    return date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;
  }

  // 检查是否为周末
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  // 获取下一个工作日
  static DateTime getNextWorkday(DateTime date) {
    DateTime nextDay = date.add(const Duration(days: 1));
    while (!isWorkday(nextDay)) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    return nextDay;
  }

  // 获取上一个工作日
  static DateTime getPreviousWorkday(DateTime date) {
    DateTime prevDay = date.subtract(const Duration(days: 1));
    while (!isWorkday(prevDay)) {
      prevDay = prevDay.subtract(const Duration(days: 1));
    }
    return prevDay;
  }

  // 计算工作日天数
  static int getWorkdaysBetween(DateTime start, DateTime end) {
    int workdays = 0;
    DateTime current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (isWorkday(current)) {
        workdays++;
      }
      current = current.add(const Duration(days: 1));
    }

    return workdays;
  }

  // 获取时间段的描述
  static String getTimePeriodDescription(DateTime start, DateTime end) {
    if (isToday(start) && isToday(end)) {
      return '今天 ${formatChineseTime(start)} - ${formatChineseTime(end)}';
    } else if (isTomorrow(start) && isTomorrow(end)) {
      return '明天 ${formatChineseTime(start)} - ${formatChineseTime(end)}';
    } else {
      return '${formatChineseDate(start)} ${formatChineseTime(start)} - '
          '${formatChineseDate(end)} ${formatChineseTime(end)}';
    }
  }

  // 检查时间是否重叠
  static bool isTimeOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  // 获取最接近的15分钟间隔时间
  static DateTime getNearestQuarterHour(DateTime date) {
    final int minutes = date.minute;
    final int remainder = minutes % 15;
    if (remainder == 0) return date;

    final int newMinutes = minutes - remainder + (remainder >= 8 ? 15 : 0);
    return DateTime(date.year, date.month, date.day, date.hour, newMinutes);
  }

  // 获取最接近的30分钟间隔时间
  static DateTime getNearestHalfHour(DateTime date) {
    final int minutes = date.minute;
    final int remainder = minutes % 30;
    if (remainder == 0) return date;

    final int newMinutes = minutes - remainder + (remainder >= 15 ? 30 : 0);
    return DateTime(date.year, date.month, date.day, date.hour, newMinutes);
  }
}
