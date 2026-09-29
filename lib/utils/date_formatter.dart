import 'package:intl/intl.dart';

class DateFormatter {
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    final timeStr = DateFormat('h:mm a').format(date);

    if (targetDate == today) {
      return 'Today, $timeStr';
    } else if (targetDate == yesterday) {
      return 'Yesterday, $timeStr';
    } else if (now.difference(date).inDays < 7) {
      return '${DateFormat('EEEE').format(date)}, $timeStr';
    } else {
      return '${DateFormat('dd MMM').format(date)}, $timeStr';
    }
  }

  static String formatDateOnly(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) return 'Today';
    if (targetDate == yesterday) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatDueDate(int dayOfMonth) {
    final now = DateTime.now();
    final day = dayOfMonth
        .clamp(1, DateTime(now.year, now.month + 1, 0).day)
        .toInt();
    DateTime due = DateTime(now.year, now.month, day);
    if (due.isBefore(DateTime(now.year, now.month, now.day))) {
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final nextDay = dayOfMonth
          .clamp(1, DateTime(nextMonth.year, nextMonth.month + 1, 0).day)
          .toInt();
      due = DateTime(nextMonth.year, nextMonth.month, nextDay);
    }
    final diff = due.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    if (diff > 1) return 'Due in $diff days';
    return 'Overdue';
  }
}
