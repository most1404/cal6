import 'package:shamsi_date/shamsi_date.dart';

class JalaliHelper {
  static const List<String> persianMonths = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];

  static const List<String> persianWeekdays = [
    'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'
  ];

  /// تبدیل اعداد به ارقام فارسی
  static String toPersianDigits(dynamic input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    String result = input.toString();
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  /// دریافت تاریخ جلالی کنونی
  static Jalali now() {
    return Jalali.now();
  }

  /// فرمت دهی تاریخ جلالی به همراه ساعت
  static String formatJalali(Jalali jalali, {int? hour, int? minute}) {
    final day = toPersianDigits(jalali.day);
    final month = persianMonths[jalali.month - 1];
    final year = toPersianDigits(jalali.year);

    if (hour != null && minute != null) {
      final hStr = toPersianDigits(hour.toString().padLeft(2, '0'));
      final mStr = toPersianDigits(minute.toString().padLeft(2, '0'));
      return '$day $month $year ساعت $hStr:$mStr';
    }
    return '$day $month $year';
  }

  /// دریافت لیست سال‌های معتبر به صورت پویا (بدون هاردکد کردن)
  static List<int> getSupportedYears({int pastYears = 5, int futureYears = 10}) {
    final currentYear = Jalali.now().year;
    final List<int> years = [];
    for (int y = currentYear - pastYears; y <= currentYear + futureYears; y++) {
      years.add(y);
    }
    return years;
  }

  /// تشخیص سال کبیسه جلالی
  static bool isLeapYear(int year) {
    return Jalali(year, 1, 1).isLeapYear();
  }

  /// برچسب کوتاه نسبی ایمن در برابر ساعت تابستانی (DST-Immune) با استفاده از julianDayNumber
  static String getRelativeLabel(Jalali jalali, {int? hour, int? minute}) {
    final nowJ = Jalali.now();
    final today = Jalali(nowJ.year, nowJ.month, nowJ.day);
    final target = Jalali(jalali.year, jalali.month, jalali.day);

    // محاسبه دقیق تفاوت روزها با julianDayNumber به جای اختلاف میلی‌ثانیه‌ای DateTime برای جلوگیری از باگ DST
    final diff = target.julianDayNumber - today.julianDayNumber;

    String timeSuffix = '';
    if (hour != null && minute != null) {
      final hStr = toPersianDigits(hour.toString().padLeft(2, '0'));
      final mStr = toPersianDigits(minute.toString().padLeft(2, '0'));
      timeSuffix = '، $hStr:$mStr';
    }

    if (diff == 0) return 'امروز$timeSuffix';
    if (diff == 1) return 'فردا$timeSuffix';
    if (diff == -1) return 'دیروز (گذشته)';
    if (diff < -1) return '${toPersianDigits(jalali.day)} ${persianMonths[jalali.month - 1]} (گذشته)';

    final weekdayName = persianWeekdays[jalali.weekDay - 1];
    return '$weekdayName، ${toPersianDigits(jalali.day)} ${persianMonths[jalali.month - 1]}$timeSuffix';
  }
}
