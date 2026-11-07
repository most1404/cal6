import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_reminder/domain/models/reminder_model.dart';
import 'package:shamsi_reminder/domain/models/subtask_model.dart';

void main() {
  group('ReminderModel copyWith & Serialization Tests', () {
    test('copyWith clears dueDate explicitly when clearDueDate is true', () {
      final original = ReminderModel(
        id: 'test-1',
        title: 'Original Title',
        memo: 'Some Memo',
        jalaliYear: 1403,
        jalaliMonth: 8,
        jalaliDay: 15,
        hour: 10,
        minute: 30,
        createdAt: DateTime.now(),
      );

      final cleared = original.copyWith(clearDueDate: true);

      expect(cleared.jalaliYear, isNull);
      expect(cleared.jalaliMonth, isNull);
      expect(cleared.jalaliDay, isNull);
      expect(cleared.hour, isNull);
      expect(cleared.minute, isNull);
      expect(cleared.hasDueDate, isFalse);
      expect(cleared.title, 'Original Title');
      expect(cleared.memo, 'Some Memo');
    });

    test('copyWith clears memo explicitly when clearMemo is true', () {
      final original = ReminderModel(
        id: 'test-2',
        title: 'Title',
        memo: 'Has Memo',
        createdAt: DateTime.now(),
      );

      final cleared = original.copyWith(clearMemo: true);

      expect(cleared.memo, isNull);
    });

    test('toMap and fromMap preserve all fields and subtasks correctly', () {
      final original = ReminderModel(
        id: 'test-3',
        title: 'Comprehensive Reminder',
        memo: 'Detailed notes',
        priority: Priority.high,
        recurrence: RecurrenceType.weekly,
        recurrenceInterval: 2,
        recurrenceDays: const [0, 2, 4],
        subtasks: const [
          SubTaskModel(id: 'st-1', reminderId: 'test-3', title: 'Task 1', isCompleted: true, orderIndex: 0),
          SubTaskModel(id: 'st-2', reminderId: 'test-3', title: 'Task 2', isCompleted: false, orderIndex: 1),
        ],
        createdAt: DateTime(2024, 11, 5, 12, 0),
      );

      final map = original.toMap();
      final reconstructed = ReminderModel.fromMap(map);

      expect(reconstructed.id, original.id);
      expect(reconstructed.title, original.title);
      expect(reconstructed.priority, Priority.high);
      expect(reconstructed.recurrence, RecurrenceType.weekly);
      expect(reconstructed.recurrenceDays, [0, 2, 4]);
      expect(reconstructed.subtasks.length, 2);
      expect(reconstructed.subtasks.first.isCompleted, isTrue);
    });
  });
}
