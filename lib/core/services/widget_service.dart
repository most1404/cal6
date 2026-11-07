import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/reminder_model.dart';
import '../utils/jalali_helper.dart';

enum WidgetFontSize { small, medium, large }

class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  static const String appWidgetProvider = 'ReminderWidgetProvider';
  static const String keyFontSize = 'widget_font_size';

  Future<void> init() async {
    await HomeWidget.setAppGroupId('group.com.example.shamsi_reminder');
  }

  /// دریافت اندازه فعلی فونت ویجت
  Future<WidgetFontSize> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(keyFontSize) ?? 'medium';
    switch (saved) {
      case 'small':
        return WidgetFontSize.small;
      case 'large':
        return WidgetFontSize.large;
      default:
        return WidgetFontSize.medium;
    }
  }

  /// تغییر اندازه فونت ویجت (۳ سطح: کوچک، متوسط، بزرگ) و اعمال آنی
  Future<void> setFontSize(WidgetFontSize size) async {
    final prefs = await SharedPreferences.getInstance();
    final strVal = size == WidgetFontSize.small
        ? 'small'
        : (size == WidgetFontSize.large ? 'large' : 'medium');

    await prefs.setString(keyFontSize, strVal);
    await HomeWidget.saveWidgetData<String>(keyFontSize, strVal);

    // Update widget view immediately
    await HomeWidget.updateWidget(
      name: appWidgetProvider,
      androidName: appWidgetProvider,
    );
  }

  /// به روز رسانی آنی داده‌های نمایش داده شده در ویجت هوماسکرین
  Future<void> updateWidgetData(List<ReminderModel> activeReminders) async {
    final today = JalaliHelper.now();
    final todayStr = JalaliHelper.formatJalali(today);

    // Save header info
    await HomeWidget.saveWidgetData<String>('widget_header_title', 'یادآورهای فعال');
    await HomeWidget.saveWidgetData<String>('widget_shamsi_date', todayStr);
    await HomeWidget.saveWidgetData<int>('widget_active_count', activeReminders.length);

    // Serialize items list for Android RemoteViewsFactory ListView
    final listJson = jsonEncode(activeReminders.map((r) {
      String timeStr = '';
      if (r.hour != null && r.minute != null) {
        timeStr = '${JalaliHelper.toPersianDigits(r.hour.toString().padLeft(2, '0'))}:${JalaliHelper.toPersianDigits(r.minute.toString().padLeft(2, '0'))}';
      }
      return {
        'id': r.id,
        'title': r.title,
        'time': timeStr,
        'isCompleted': r.isCompleted,
        'priority': r.priority.name,
      };
    }).toList());
    await HomeWidget.saveWidgetData<String>('widget_reminders_json', listJson);

    // Trigger Android AppWidget update
    await HomeWidget.updateWidget(
      name: appWidgetProvider,
      androidName: appWidgetProvider,
    );
  }
}
