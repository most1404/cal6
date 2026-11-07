import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';
import '../bloc/reminder_state.dart';

class CompletedRemindersScreen extends StatelessWidget {
  const CompletedRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('انجام‌شده‌ها'),
      ),
      body: BlocBuilder<ReminderBloc, ReminderState>(
        builder: (context, state) {
          final list = state.completedReminders;
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'هنوز هیچ یادآوری تکمیل نشده است.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final reminder = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: AppColors.catPersonal),
                  title: Text(
                    reminder.title,
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: AppColors.textStrikethrough,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore_rounded, color: AppColors.primaryBlue),
                        tooltip: 'بازگردانی',
                        onPressed: () {
                          context.read<ReminderBloc>().add(RestoreCompletedReminderEvent(reminder.id));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.priorityHigh),
                        tooltip: 'حذف',
                        onPressed: () {
                          context.read<ReminderBloc>().add(DeleteReminderEvent(reminder.id));
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
