import 'package:shamsi_date/shamsi_date.dart';
import '../../domain/models/reminder_model.dart';

class RecurrenceEngine {
  RecurrenceEngine._();

  /// محاسبه تاریخ وقوع بعدی بر اساس نوع تکرار، بازه تناوب و روزهای انتخابی هفته
  static Jalali? calculateNextOccurrence({
    required Jalali currentJalali,
    required RecurrenceType type,
    int interval = 1,
    List<int> recurrenceDays = const [],
    DateTime? endDate,
  }) {
    if (type == RecurrenceType.none) return null;
    final safeInterval = interval < 1 ? 1 : interval;

    Jalali next;

    switch (type) {
      case RecurrenceType.daily:
        next = currentJalali.addDays(safeInterval);
        break;

      case RecurrenceType.weekly:
        if (recurrenceDays.isEmpty) {
          next = currentJalali.addDays(7 * safeInterval);
        } else {
          final currentIdx = currentJalali.weekDay - 1; // 0=Sat..6=Fri
          final sortedDays = List<int>.from(recurrenceDays)..sort();
          int? nextOffset;

          for (final dayIdx in sortedDays) {
            if (dayIdx > currentIdx) {
              nextOffset = dayIdx - currentIdx;
              break;
            }
          }

          if (nextOffset != null) {
            next = currentJalali.addDays(nextOffset);
          } else {
            final firstDay = sortedDays.first;
            final daysToEndOfWeek = 7 - currentIdx;
            final additionalWeeks = safeInterval - 1;
            next = currentJalali.addDays(daysToEndOfWeek + (additionalWeeks * 7) + firstDay);
          }
        }
        break;

      case RecurrenceType.monthly:
        int targetYear = currentJalali.year;
        int targetMonth = currentJalali.month + safeInterval;
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear += 1;
        }

        // Clamp day: Handle 30/29 day months (Esfand, etc.)
        final daysInMonth = Jalali(targetYear, targetMonth, 1).monthLength;
        final targetDay = currentJalali.day > daysInMonth ? daysInMonth : currentJalali.day;
        next = Jalali(targetYear, targetMonth, targetDay);
        break;

      case RecurrenceType.yearly:
        int targetYear = currentJalali.year + safeInterval;
        int targetMonth = currentJalali.month;
        int targetDay = currentJalali.day;

        final daysInMonth = Jalali(targetYear, targetMonth, 1).monthLength;
        if (targetDay > daysInMonth) {
          targetDay = daysInMonth;
        }
        next = Jalali(targetYear, targetMonth, targetDay);
        break;

      case RecurrenceType.none:
        return null;
    }

    // Cutoff check
    if (endDate != null) {
      if (next.toDateTime().isAfter(endDate)) {
        return null;
      }
    }

    return next;
  }
}
