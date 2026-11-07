import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/recurrence_engine.dart';
import '../../core/services/widget_service.dart';
import '../../data/datasources/database_helper.dart';
import '../../domain/models/reminder_model.dart';
import 'reminder_event.dart';
import 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final WidgetService _widgetService = WidgetService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  ReminderBloc() : super(const ReminderState()) {
    on<LoadRemindersEvent>(_onLoadReminders);
    on<AddReminderEvent>(_onAddReminder);
    on<UpdateReminderEvent>(_onUpdateReminder);
    on<ToggleMainReminderEvent>(_onToggleMainReminder);
    on<ToggleSubTaskEvent>(_onToggleSubTask);
    on<SnoozeReminderEvent>(_onSnoozeReminder);
    on<RestoreCompletedReminderEvent>(_onRestoreReminder);
    on<DeleteReminderEvent>(_onDeleteReminder);
    on<FilterCategoryEvent>(_onFilterCategory);
    on<ChangeWidgetFontSizeEvent>(_onChangeWidgetFontSize);
  }

  Future<void> _onLoadReminders(
      LoadRemindersEvent event, Emitter<ReminderState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await _db.getAllReminders();
      final fontSize = await _widgetService.getFontSize();
      emit(state.copyWith(
        reminders: list,
        isLoading: false,
        widgetFontSize: fontSize,
      ));
      _syncWidget(list);
      // Reconcile scheduled alarms with Android system
      await _notificationService.reconcileScheduledAlarms(list);
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onAddReminder(
      AddReminderEvent event, Emitter<ReminderState> emit) async {
    await _db.insertReminder(event.reminder);
    final updated = List<ReminderModel>.from(state.reminders)..insert(0, event.reminder);
    emit(state.copyWith(reminders: updated));
    _syncWidget(updated);

    if (event.reminder.hasDueDate && event.reminder.hour != null) {
      final jDate = Jalali(
        event.reminder.jalaliYear!,
        event.reminder.jalaliMonth!,
        event.reminder.jalaliDay!,
        event.reminder.hour!,
        event.reminder.minute ?? 0,
      );
      await _notificationService.scheduleReminderNotification(
        id: event.reminder.notificationId ?? (event.reminder.id.hashCode.abs() % 2147483647),
        title: event.reminder.title,
        body: event.reminder.memo ?? 'سررسید یادآور',
        scheduledDate: jDate.toDateTime(),
      );
    }
  }

  Future<void> _onUpdateReminder(
      UpdateReminderEvent event, Emitter<ReminderState> emit) async {
    await _db.updateReminder(event.reminder);
    final updated = state.reminders.map((r) => r.id == event.reminder.id ? event.reminder : r).toList();
    emit(state.copyWith(reminders: updated));
    _syncWidget(updated);
  }

  /// تیک زدن یادآور اصلی:
  /// - انیمیشن محو و ثبت در انجام‌شده‌ها
  /// - اگر یادآور تکرارشونده باشد، رخداد بعدی آن با موتور RecurrenceEngine محاسبه و ساخته می‌شود
  Future<void> _onToggleMainReminder(
      ToggleMainReminderEvent event, Emitter<ReminderState> emit) async {
    final item = state.reminders.firstWhere((r) => r.id == event.reminderId);
    final willComplete = !item.isCompleted;

    final updatedItem = item.copyWith(
      isCompleted: willComplete,
      completedAt: willComplete ? DateTime.now() : null,
      clearCompletedAt: !willComplete,
    );

    await _db.updateReminder(updatedItem);

    final updatedList = state.reminders.map((r) => r.id == event.reminderId ? updatedItem : r).toList();

    // Spawn next recurrence instance if completing
    if (willComplete && item.recurrence != RecurrenceType.none && item.hasDueDate) {
      final currentJ = Jalali(item.jalaliYear!, item.jalaliMonth!, item.jalaliDay!);
      final nextJ = RecurrenceEngine.calculateNextOccurrence(
        currentJalali: currentJ,
        type: item.recurrence,
        interval: item.recurrenceInterval,
        recurrenceDays: item.recurrenceDays,
        endDate: item.recurrenceEndDate,
      );

      if (nextJ != null) {
        final nextReminder = item.copyWith(
          id: const Uuid().v4(),
          jalaliYear: nextJ.year,
          jalaliMonth: nextJ.month,
          jalaliDay: nextJ.day,
          isCompleted: false,
          clearCompletedAt: true,
          clearSnooze: true,
          subtasks: item.subtasks.map((st) => st.copyWith(id: const Uuid().v4(), isCompleted: false)).toList(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _db.insertReminder(nextReminder);
        updatedList.insert(0, nextReminder);

        if (nextReminder.hour != null) {
          final nextDt = Jalali(nextJ.year, nextJ.month, nextJ.day, nextReminder.hour!, nextReminder.minute ?? 0).toDateTime();
          await _notificationService.scheduleReminderNotification(
            id: nextReminder.notificationId ?? (nextReminder.id.hashCode.abs() % 2147483647),
            title: nextReminder.title,
            body: nextReminder.memo ?? 'سررسید یادآور',
            scheduledDate: nextDt,
          );
        }
      }
    }

    emit(state.copyWith(reminders: updatedList));
    _syncWidget(updatedList);
  }

  /// تیک زدن زیرمجموعه: فقط همان مورد خط می‌خورد و کمی محو می‌شود (حذف کامل نمی‌شود)
  Future<void> _onToggleSubTask(
      ToggleSubTaskEvent event, Emitter<ReminderState> emit) async {
    final item = state.reminders.firstWhere((r) => r.id == event.reminderId);
    final updatedSubtasks = item.subtasks.map((st) {
      if (st.id == event.subTaskId) {
        return st.copyWith(isCompleted: !st.isCompleted);
      }
      return st;
    }).toList();

    final updatedItem = item.copyWith(subtasks: updatedSubtasks);
    await _db.updateReminder(updatedItem);

    final updatedList = state.reminders.map((r) => r.id == event.reminderId ? updatedItem : r).toList();
    emit(state.copyWith(reminders: updatedList));
  }

  /// به تعویق انداختن یادآور (Snooze ایمن با هندل عبور از نیمه‌شب)
  Future<void> _onSnoozeReminder(
      SnoozeReminderEvent event, Emitter<ReminderState> emit) async {
    final item = state.reminders.firstWhere((r) => r.id == event.reminderId);

    int? targetYear = event.newJalaliYear ?? item.jalaliYear;
    int? targetMonth = event.newJalaliMonth ?? item.jalaliMonth;
    int? targetDay = event.newJalaliDay ?? item.jalaliDay;

    // Check if rolled past midnight without explicit date
    if (event.newJalaliDay == null && item.hour != null && targetYear != null && targetMonth != null && targetDay != null) {
      if (event.newHour < item.hour! || (event.newHour == item.hour! && event.newMinute <= (item.minute ?? 0))) {
        final nextDayJ = Jalali(targetYear, targetMonth, targetDay).addDays(1);
        targetYear = nextDayJ.year;
        targetMonth = nextDayJ.month;
        targetDay = nextDayJ.day;
      }
    }

    final updatedItem = item.copyWith(
      isSnoozed: true,
      hour: event.newHour,
      minute: event.newMinute,
      jalaliDay: targetDay,
      jalaliMonth: targetMonth,
      jalaliYear: targetYear,
      snoozeUntil: DateTime.now().add(const Duration(minutes: 15)),
    );

    await _db.updateReminder(updatedItem);
    final updatedList = state.reminders.map((r) => r.id == event.reminderId ? updatedItem : r).toList();
    emit(state.copyWith(reminders: updatedList));
  }

  Future<void> _onRestoreReminder(
      RestoreCompletedReminderEvent event, Emitter<ReminderState> emit) async {
    final item = state.reminders.firstWhere((r) => r.id == event.reminderId);
    final updatedItem = item.copyWith(isCompleted: false, clearCompletedAt: true);
    await _db.updateReminder(updatedItem);

    final updatedList = state.reminders.map((r) => r.id == event.reminderId ? updatedItem : r).toList();
    emit(state.copyWith(reminders: updatedList));
    _syncWidget(updatedList);
  }

  Future<void> _onDeleteReminder(
      DeleteReminderEvent event, Emitter<ReminderState> emit) async {
    await _db.deleteReminder(event.reminderId);
    final updatedList = state.reminders.where((r) => r.id != event.reminderId).toList();
    emit(state.copyWith(reminders: updatedList));
    _syncWidget(updatedList);
  }

  void _onFilterCategory(
      FilterCategoryEvent event, Emitter<ReminderState> emit) {
    emit(state.copyWith(selectedCategoryId: event.categoryId));
  }

  Future<void> _onChangeWidgetFontSize(
      ChangeWidgetFontSizeEvent event, Emitter<ReminderState> emit) async {
    await _widgetService.setFontSize(event.newSize);
    emit(state.copyWith(widgetFontSize: event.newSize));
  }

  void _syncWidget(List<ReminderModel> list) {
    final active = list.where((r) => !r.isCompleted).toList();
    _widgetService.updateWidgetData(active);
  }
}
