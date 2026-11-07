import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shamsi_reminder/core/services/recurrence_engine.dart';
import 'package:shamsi_reminder/domain/models/reminder_model.dart';

void main() {
  group('RecurrenceEngine Tests', () {
    test('Daily recurrence advances by specified interval', () {
      final start = Jalali(1403, 8, 15);
      final next = RecurrenceEngine.calculateNextOccurrence(
        currentJalali: start,
        type: RecurrenceType.daily,
        interval: 1,
      );

      expect(next, isNotNull);
      expect(next!.year, 1403);
      expect(next.month, 8);
      expect(next.day, 16);
    });

    test('Monthly recurrence on day 31 clamps to 30 for 30-day Persian months', () {
      // Mordad 31 (month 5 has 31 days) -> next month Shahrivar (month 6 has 31 days)
      // Shahrivar 31 -> next month Mehr (month 7 has 30 days, must clamp to 30!)
      final shahrivar31 = Jalali(1403, 6, 31);
      final nextMonth = RecurrenceEngine.calculateNextOccurrence(
        currentJalali: shahrivar31,
        type: RecurrenceType.monthly,
        interval: 1,
      );

      expect(nextMonth, isNotNull);
      expect(nextMonth!.year, 1403);
      expect(nextMonth.month, 7); // Mehr
      expect(nextMonth.day, 30);  // Clamped to 30!
    });

    test('Monthly recurrence on Bahman 30 clamps to 29 in Esfand (non-leap year)', () {
      final bahman30 = Jalali(1403, 11, 30);
      final nextMonth = RecurrenceEngine.calculateNextOccurrence(
        currentJalali: bahman30,
        type: RecurrenceType.monthly,
        interval: 1,
      );

      expect(nextMonth, isNotNull);
      expect(nextMonth!.year, 1403);
      expect(nextMonth.month, 12); // Esfand
      expect(nextMonth.day, 29);   // Clamped to 29!
    });

    test('Weekly recurrence with specific weekday flags jumps correctly', () {
      // 1403/8/15 is Tuesday (weekDay = 4 in shamsi_date, index = 3)
      final tuesday = Jalali(1403, 8, 15);
      // Select Thursday (index 5)
      final next = RecurrenceEngine.calculateNextOccurrence(
        currentJalali: tuesday,
        type: RecurrenceType.weekly,
        recurrenceDays: [5], // Thursday
      );

      expect(next, isNotNull);
      expect(next!.weekDay, 6); // shamsi_date Thursday is 6
    });

    test('Recurrence respects endDate cutoff and returns null if exceeded', () {
      final start = Jalali(1403, 8, 15);
      final endDate = DateTime(2024, 11, 6); // Before the next day
      final next = RecurrenceEngine.calculateNextOccurrence(
        currentJalali: start,
        type: RecurrenceType.daily,
        interval: 5,
        endDate: endDate,
      );

      expect(next, isNull);
    });
  });
}
