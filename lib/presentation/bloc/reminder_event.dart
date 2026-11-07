import 'package:equatable/equatable.dart';
import '../../core/services/widget_service.dart';
import '../../domain/models/reminder_model.dart';

abstract class ReminderEvent extends Equatable {
  const ReminderEvent();
  @override
  List<Object?> get props => [];
}

class LoadRemindersEvent extends ReminderEvent {
  const LoadRemindersEvent();
}

class AddReminderEvent extends ReminderEvent {
  final ReminderModel reminder;
  const AddReminderEvent(this.reminder);
  @override
  List<Object?> get props => [reminder];
}

class UpdateReminderEvent extends ReminderEvent {
  final ReminderModel reminder;
  const UpdateReminderEvent(this.reminder);
  @override
  List<Object?> get props => [reminder];
}

class ToggleMainReminderEvent extends ReminderEvent {
  final String reminderId;
  const ToggleMainReminderEvent(this.reminderId);
  @override
  List<Object?> get props => [reminderId];
}

class ToggleSubTaskEvent extends ReminderEvent {
  final String reminderId;
  final String subTaskId;
  const ToggleSubTaskEvent({required this.reminderId, required this.subTaskId});
  @override
  List<Object?> get props => [reminderId, subTaskId];
}

class SnoozeReminderEvent extends ReminderEvent {
  final String reminderId;
  final int newHour;
  final int newMinute;
  final int? newJalaliYear;
  final int? newJalaliMonth;
  final int? newJalaliDay;

  const SnoozeReminderEvent({
    required this.reminderId,
    required this.newHour,
    required this.newMinute,
    this.newJalaliYear,
    this.newJalaliMonth,
    this.newJalaliDay,
  });

  @override
  List<Object?> get props => [reminderId, newHour, newMinute, newJalaliYear, newJalaliMonth, newJalaliDay];
}

class RestoreCompletedReminderEvent extends ReminderEvent {
  final String reminderId;
  const RestoreCompletedReminderEvent(this.reminderId);
  @override
  List<Object?> get props => [reminderId];
}

class DeleteReminderEvent extends ReminderEvent {
  final String reminderId;
  const DeleteReminderEvent(this.reminderId);
  @override
  List<Object?> get props => [reminderId];
}

class FilterCategoryEvent extends ReminderEvent {
  final String categoryId;
  const FilterCategoryEvent(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

class ChangeWidgetFontSizeEvent extends ReminderEvent {
  final WidgetFontSize newSize;
  const ChangeWidgetFontSizeEvent(this.newSize);
  @override
  List<Object?> get props => [newSize];
}
