import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'subtask_model.dart';

enum RecurrenceType { none, daily, weekly, monthly, yearly }
enum Priority { none, low, medium, high }

class ReminderModel extends Equatable {
  final String id;
  final String title;
  final String? memo;
  final String categoryId;
  final Priority priority;
  final int? jalaliYear;
  final int? jalaliMonth;
  final int? jalaliDay;
  final int? hour;
  final int? minute;
  final RecurrenceType recurrence;
  final int recurrenceInterval;
  final List<int> recurrenceDays; // 0=Saturday, 1=Sunday, ..., 6=Friday
  final DateTime? recurrenceEndDate;
  final DateTime? nextOccurrence;
  final int? notificationId;
  final List<SubTaskModel> subtasks;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSnoozed;
  final DateTime? snoozeUntil;

  const ReminderModel({
    required this.id,
    required this.title,
    this.memo,
    this.categoryId = 'work',
    this.priority = Priority.none,
    this.jalaliYear,
    this.jalaliMonth,
    this.jalaliDay,
    this.hour,
    this.minute,
    this.recurrence = RecurrenceType.none,
    this.recurrenceInterval = 1,
    this.recurrenceDays = const [],
    this.recurrenceEndDate,
    this.nextOccurrence,
    this.notificationId,
    this.subtasks = const [],
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    this.updatedAt,
    this.isSnoozed = false,
    this.snoozeUntil,
  });

  bool get hasDueDate => jalaliYear != null && jalaliMonth != null && jalaliDay != null;

  /// کپی ایمن با امکان پاک‌سازی صریح مقادیر Nullable بدون نادیده گرفته شدن
  ReminderModel copyWith({
    String? id,
    String? title,
    String? memo,
    bool clearMemo = false,
    String? categoryId,
    Priority? priority,
    int? jalaliYear,
    int? jalaliMonth,
    int? jalaliDay,
    int? hour,
    int? minute,
    bool clearDueDate = false,
    RecurrenceType? recurrence,
    int? recurrenceInterval,
    List<int>? recurrenceDays,
    DateTime? recurrenceEndDate,
    DateTime? nextOccurrence,
    int? notificationId,
    List<SubTaskModel>? subtasks,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSnoozed,
    DateTime? snoozeUntil,
    bool clearSnooze = false,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      memo: clearMemo ? null : (memo ?? this.memo),
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      jalaliYear: clearDueDate ? null : (jalaliYear ?? this.jalaliYear),
      jalaliMonth: clearDueDate ? null : (jalaliMonth ?? this.jalaliMonth),
      jalaliDay: clearDueDate ? null : (jalaliDay ?? this.jalaliDay),
      hour: clearDueDate ? null : (hour ?? this.hour),
      minute: clearDueDate ? null : (minute ?? this.minute),
      recurrence: recurrence ?? this.recurrence,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      notificationId: notificationId ?? this.notificationId,
      subtasks: subtasks ?? this.subtasks,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt ?? DateTime.now(),
      isSnoozed: clearSnooze ? false : (isSnoozed ?? this.isSnoozed),
      snoozeUntil: clearSnooze ? null : (snoozeUntil ?? this.snoozeUntil),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'memo': memo,
      'categoryId': categoryId,
      'priority': priority.name,
      'jalaliYear': jalaliYear,
      'jalaliMonth': jalaliMonth,
      'jalaliDay': jalaliDay,
      'hour': hour,
      'minute': minute,
      'recurrence': recurrence.name,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceDays': jsonEncode(recurrenceDays),
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'nextOccurrence': nextOccurrence?.toIso8601String(),
      'notificationId': notificationId ?? id.hashCode.abs() % 2147483647,
      'subtasksJson': jsonEncode(subtasks.map((e) => e.toMap()).toList()),
      'isCompleted': isCompleted ? 1 : 0,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
      'isSnoozed': isSnoozed ? 1 : 0,
      'snoozeUntil': snoozeUntil?.toIso8601String(),
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map, {List<SubTaskModel>? explicitSubtasks}) {
    List<SubTaskModel> parsedSubtasks = explicitSubtasks ?? [];
    if (parsedSubtasks.isEmpty && map['subtasksJson'] != null) {
      try {
        final List decoded = jsonDecode(map['subtasksJson'] as String);
        parsedSubtasks = decoded.map((e) => SubTaskModel.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    List<int> parsedRecurrenceDays = [];
    if (map['recurrenceDays'] != null) {
      try {
        final dynamic rawDays = map['recurrenceDays'];
        if (rawDays is String && rawDays.isNotEmpty) {
          final List decoded = jsonDecode(rawDays);
          parsedRecurrenceDays = decoded.map((e) => e as int).toList();
        } else if (rawDays is List) {
          parsedRecurrenceDays = rawDays.map((e) => e as int).toList();
        }
      } catch (_) {}
    }

    return ReminderModel(
      id: map['id'] as String,
      title: map['title'] as String,
      memo: map['memo'] as String?,
      categoryId: (map['categoryId'] as String?) ?? 'work',
      priority: Priority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => Priority.none,
      ),
      jalaliYear: map['jalaliYear'] as int?,
      jalaliMonth: map['jalaliMonth'] as int?,
      jalaliDay: map['jalaliDay'] as int?,
      hour: map['hour'] as int?,
      minute: map['minute'] as int?,
      recurrence: RecurrenceType.values.firstWhere(
        (e) => e.name == map['recurrence'],
        orElse: () => RecurrenceType.none,
      ),
      recurrenceInterval: (map['recurrenceInterval'] as int?) ?? 1,
      recurrenceDays: parsedRecurrenceDays,
      recurrenceEndDate: map['recurrenceEndDate'] != null ? DateTime.tryParse(map['recurrenceEndDate'] as String) : null,
      nextOccurrence: map['nextOccurrence'] != null ? DateTime.tryParse(map['nextOccurrence'] as String) : null,
      notificationId: map['notificationId'] as int?,
      subtasks: parsedSubtasks,
      isCompleted: (map['isCompleted'] as int) == 1,
      completedAt: map['completedAt'] != null ? DateTime.tryParse(map['completedAt'] as String) : null,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'] as String) : null,
      isSnoozed: (map['isSnoozed'] as int?) == 1,
      snoozeUntil: map['snoozeUntil'] != null ? DateTime.tryParse(map['snoozeUntil'] as String) : null,
    );
  }

  @override
  List<Object?> get props => [
    id, title, memo, categoryId, priority,
    jalaliYear, jalaliMonth, jalaliDay, hour, minute,
    recurrence, recurrenceInterval, recurrenceDays, recurrenceEndDate, nextOccurrence,
    notificationId, subtasks, isCompleted, completedAt, createdAt, updatedAt,
    isSnoozed, snoozeUntil,
  ];
}
