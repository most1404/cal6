import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../domain/models/reminder_model.dart' hide Priority;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final actionId = response.actionId;

        if (actionId == 'ACTION_DONE') {
          // Completed from notification
        } else if (actionId == 'ACTION_SNOOZE_15') {
          // Snooze 15 minutes
        }
      },
    );

    // Request permissions for exact alarms and notifications on Android 13+
    await checkAndRequestExactAlarmPermission();
  }

  /// بررسی و درخواست دسترسی زمان‌بندی آلارم دقیق در اندروید ۱۲ و بالاتر
  Future<bool> checkAndRequestExactAlarmPermission() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final canSchedule = await androidPlugin.canScheduleExactNotifications() ?? false;
      if (!canSchedule) {
        await androidPlugin.requestExactAlarmsPermission();
      }
      return await androidPlugin.canScheduleExactNotifications() ?? false;
    }
    return true;
  }

  /// زمان‌بندی نوتیفیکیشن با آلارم دقیق
  Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // If date has passed, ignore
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shamsi_reminders_channel',
          'یادآورهای شمسی',
          channelDescription: 'اعلان‌های سررسید یادآورهای شخصی و کاری با صدای زنگ و لرزش',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction('ACTION_DONE', 'انجام شد ✅'),
            AndroidNotificationAction('ACTION_SNOOZE_15', '۱۵ دقیقه بعد ⏰'),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// تطبیق و زمان‌بندی مجدد تمامی آلارم‌های فعال (Reconciliation بعد از بوت یا بالا آمدن برنامه)
  Future<void> reconcileScheduledAlarms(List<ReminderModel> activeReminders) async {
    for (final reminder in activeReminders) {
      if (!reminder.isCompleted && reminder.hasDueDate) {
        final jDate = Jalali(
          reminder.jalaliYear!,
          reminder.jalaliMonth!,
          reminder.jalaliDay!,
          reminder.hour ?? 10,
          reminder.minute ?? 0,
        );
        final dt = jDate.toDateTime();
        if (dt.isAfter(DateTime.now())) {
          final notifId = reminder.notificationId ?? (reminder.id.hashCode.abs() % 2147483647);
          await scheduleReminderNotification(
            id: notifId,
            title: reminder.title,
            body: reminder.memo ?? 'سررسید یادآور فرا رسیده است',
            scheduledDate: dt,
          );
        }
      }
    }
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}
