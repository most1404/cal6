import 'package:shamsi_date/shamsi_date.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../domain/models/reminder_model.dart';

class ParsedVoiceResult {
  final String title;
  final Jalali? jalaliDate;
  final int? hour;
  final int? minute;
  final bool hasTime;
  final RecurrenceType recurrence;

  ParsedVoiceResult({
    required this.title,
    this.jalaliDate,
    this.hour,
    this.minute,
    this.hasTime = false,
    this.recurrence = RecurrenceType.none,
  });
}

class VoiceNlpService {
  VoiceNlpService._();
  static final VoiceNlpService instance = VoiceNlpService._();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initSpeech() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize();
    }
    return _isInitialized;
  }

  /// نرمال‌سازی نویسه‌های عربی به فارسی و تبدیل ارقام
  static String normalizePersianText(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String text = input
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('ۀ', 'ه')
        .replaceAll('ة', 'ت')
        .replaceAll('‌', ' '); // Replace ZWNJ with space for token matching

    for (int i = 0; i < 10; i++) {
      text = text.replaceAll(arabicDigits[i], englishDigits[i]);
    }
    return text;
  }

  /// استخراج هوشمند عنوان، تاریخ شمسی، ساعت و تکرار از گفتار فارسی
  ParsedVoiceResult parsePersianVoiceText(String speechText) {
    String text = normalizePersianText(speechText).trim();
    final now = Jalali.now();
    Jalali targetDate = now;
    int? hour;
    int? minute;
    bool hasDate = false;
    bool hasTime = false;
    RecurrenceType recurrence = RecurrenceType.none;

    // 1. بررسی عبارات تکرار
    if (text.contains('هر روز')) {
      recurrence = RecurrenceType.daily;
      text = text.replaceAll('هر روز', '');
    } else if (text.contains('هر هفته')) {
      recurrence = RecurrenceType.weekly;
      text = text.replaceAll('هر هفته', '');
    } else if (text.contains('هر ماه')) {
      recurrence = RecurrenceType.monthly;
      text = text.replaceAll('هر ماه', '');
    } else if (text.contains('هر سال')) {
      recurrence = RecurrenceType.yearly;
      text = text.replaceAll('هر سال', '');
    }

    // 2. بررسی روزهای نسبی: فردا، پس فردا، امروز
    if (text.contains('پس فردا')) {
      targetDate = targetDate.addDays(2);
      hasDate = true;
      text = text.replaceAll(RegExp(r'پس\s*فردا'), '');
    } else if (text.contains('فردا')) {
      targetDate = targetDate.addDays(1);
      hasDate = true;
      text = text.replaceAll('فردا', '');
    } else if (text.contains('امروز')) {
      hasDate = true;
      text = text.replaceAll('امروز', '');
    }

    // 3. بررسی روزهای هفته
    final weekdaysMap = {
      'شنبه': 1,
      'یکشنبه': 2,
      'دوشنبه': 3,
      'سه شنبه': 4,
      'سه‌شنبه': 4,
      'چهارشنبه': 5,
      'پنجشنبه': 6,
      'پنج‌شنبه': 6,
      'جمعه': 7,
    };

    if (!hasDate) {
      for (final entry in weekdaysMap.entries) {
        if (text.contains(entry.key)) {
          final targetWd = entry.value;
          final currentWd = targetDate.weekDay;
          int daysDiff = (targetWd - currentWd + 7) % 7;
          if (daysDiff == 0) daysDiff = 7; // هفته بعد
          targetDate = targetDate.addDays(daysDiff);
          hasDate = true;
          text = text.replaceAll(entry.key, '');
          break;
        }
      }
    }

    // 4. استخراج ساعت: مثلا "ساعت ۱۰:۳۰"، "ساعت ۵ بعد از ظهر"، "ساعت هشت و نیم شب"
    final timeMatch = RegExp(r'ساعت\s*(\d{1,2}|یک|دو|سه|چهار|پنج|شش|شیش|هفت|هشت|نه|ده|یازده|دوازده)(?:(?::(\d{1,2}))|\s*و\s*(نیم|ربع|\d{1,2}))?\s*(صبح|عصر|شب|بعد از ظهر)?').firstMatch(text);

    if (timeMatch != null) {
      hasTime = true;
      final rawH = timeMatch.group(1);
      int h = _parseNumberWord(rawH ?? '10');

      int m = 0;
      if (timeMatch.group(2) != null) {
        m = int.tryParse(timeMatch.group(2)!) ?? 0;
      } else if (timeMatch.group(3) == 'نیم') {
        m = 30;
      } else if (timeMatch.group(3) == 'ربع') {
        m = 15;
      } else if (timeMatch.group(3) != null) {
        m = int.tryParse(timeMatch.group(3)!) ?? 0;
      }

      final modifier = timeMatch.group(4) ?? '';
      if ((modifier.contains('عصر') || modifier.contains('شب') || modifier.contains('بعد از ظهر')) && h < 12) {
        h += 12;
      } else if (modifier.contains('صبح') && h == 12) {
        h = 0;
      }

      hour = h;
      minute = m;
      text = text.replaceFirst(timeMatch.group(0)!, '');
    }

    // 5. پاکسازی عبارات اضافه از عنوان
    String cleanTitle = text
        .replaceAll(RegExp(r'^(یادم بنداز|یادآوری کن|یادم باشه|ثبت کن|به من بگو)\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleanTitle.isEmpty) {
      cleanTitle = 'یادآور صوتی';
    }

    return ParsedVoiceResult(
      title: cleanTitle,
      jalaliDate: (hasDate || hasTime) ? targetDate : null,
      hour: hour,
      minute: minute,
      hasTime: hasTime,
      recurrence: recurrence,
    );
  }

  int _parseNumberWord(String word) {
    switch (word) {
      case 'یک': return 1;
      case 'دو': return 2;
      case 'سه': return 3;
      case 'چهار': return 4;
      case 'پنج': return 5;
      case 'شش':
      case 'شیش': return 6;
      case 'هفت': return 7;
      case 'هشت': return 8;
      case 'نه': return 9;
      case 'ده': return 10;
      case 'یازده': return 11;
      case 'دوازده': return 12;
      default: return int.tryParse(word) ?? 10;
    }
  }
}
