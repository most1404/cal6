import 'package:equatable/equatable.dart';
import '../../core/services/widget_service.dart';
import '../../domain/models/reminder_model.dart';

class ReminderState extends Equatable {
  final List<ReminderModel> reminders;
  final bool isLoading;
  final String? errorMessage;
  final String selectedCategoryId;
  final WidgetFontSize widgetFontSize;

  const ReminderState({
    this.reminders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategoryId = 'all',
    this.widgetFontSize = WidgetFontSize.medium,
  });

  List<ReminderModel> get activeReminders =>
      reminders.where((r) => !r.isCompleted).toList();

  List<ReminderModel> get completedReminders =>
      reminders.where((r) => r.isCompleted).toList();

  ReminderState copyWith({
    List<ReminderModel>? reminders,
    bool? isLoading,
    String? errorMessage,
    String? selectedCategoryId,
    WidgetFontSize? widgetFontSize,
  }) {
    return ReminderState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      widgetFontSize: widgetFontSize ?? this.widgetFontSize,
    );
  }

  @override
  List<Object?> get props => [
    reminders, isLoading, errorMessage, selectedCategoryId, widgetFontSize
  ];
}
