import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shamsi_reminder/core/services/voice_nlp_service.dart';
import 'package:shamsi_reminder/domain/models/reminder_model.dart';

void main() {
  group('VoiceNlpService Persian Processing Tests', () {
    test('normalizePersianText replaces Arabic characters and digits', () {
      const input = 'جلسه با آقاي مهدوي ساعت ١٠:٣٠';
      final normalized = VoiceNlpService.normalizePersianText(input);

      expect(normalized.contains('ي'), isFalse);
      expect(normalized.contains('ی'), isTrue);
      expect(normalized.contains('10:30'), isTrue);
    });

    test('parsePersianVoiceText extracts tomorrow date and hour', () {
      const input = 'فردا ساعت ۱۰ صبح جلسه بررسی کد';
      final parsed = VoiceNlpService.instance.parsePersianVoiceText(input);

      expect(parsed.title, contains('جلسه بررسی کد'));
      expect(parsed.hasTime, isTrue);
      expect(parsed.hour, 10);
      expect(parsed.minute, 0);

      final tomorrow = Jalali.now().addDays(1);
      expect(parsed.jalaliDate, isNotNull);
      expect(parsed.jalaliDate!.day, tomorrow.day);
    });

    test('parsePersianVoiceText parses afternoon and evening time with half hour', () {
      const input = 'امروز ساعت ۵ و نیم بعد از ظهر ویزیت پزشک';
      final parsed = VoiceNlpService.instance.parsePersianVoiceText(input);

      expect(parsed.hour, 17); // 5 + 12
      expect(parsed.minute, 30); // نیم
      expect(parsed.title, contains('ویزیت پزشک'));
    });

    test('parsePersianVoiceText detects recurrence patterns', () {
      const input = 'هر هفته پنجشنبه ساعت ۹ صبح ورزش صبحگاهی';
      final parsed = VoiceNlpService.instance.parsePersianVoiceText(input);

      expect(parsed.recurrence, RecurrenceType.weekly);
      expect(parsed.hasTime, isTrue);
      expect(parsed.hour, 9);
      expect(parsed.title, contains('ورزش صبحگاهی'));
    });
  });
}
