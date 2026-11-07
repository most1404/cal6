import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/models/reminder_model.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';
import 'snooze_bottom_sheet.dart';

class ReminderCard extends StatelessWidget {
  final ReminderModel reminder;

  const ReminderCard({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x402A3445)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Checkbox: تیک زدن یادآور اصلی باعث محو شدن کل یادآور می‌شود
              GestureDetector(
                onTap: () {
                  context.read<ReminderBloc>().add(ToggleMainReminderEvent(reminder.id));
                },
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2, left: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryBlue, width: 2),
                    color: reminder.isCompleted ? AppColors.primaryBlue : Colors.transparent,
                  ),
                  child: reminder.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),

              // Title and Memo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: reminder.isCompleted ? AppColors.textStrikethrough : AppColors.textPrimary,
                        decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (reminder.memo != null && reminder.memo!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reminder.memo!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),

              // Snooze Action Button
              IconButton(
                icon: const Icon(Icons.snooze_rounded, color: AppColors.textSecondary, size: 20),
                tooltip: 'به تعویق انداختن',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SnoozeBottomSheet(reminderId: reminder.id),
                  );
                },
              ),
            ],
          ),

          // SubTasks Checklist: تیک زدن زیرمجموعه فقط همان مورد را خط می‌زند و محو نمی‌کند
          if (reminder.subtasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 8),
            ...reminder.subtasks.map((st) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.read<ReminderBloc>().add(ToggleSubTaskEvent(
                          reminderId: reminder.id,
                          subTaskId: st.id,
                        ));
                      },
                      child: Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: st.isCompleted ? AppColors.textMuted : AppColors.textSecondary,
                            width: 1.5,
                          ),
                          color: st.isCompleted ? const Color(0x4D64748B) : Colors.transparent,
                        ),
                        child: st.isCompleted
                            ? const Icon(Icons.check, size: 13, color: AppColors.textMuted)
                            : null,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        st.title,
                        style: TextStyle(
                          fontSize: 13,
                          color: st.isCompleted ? const Color(0x9964748B) : AppColors.textPrimary,
                          decoration: st.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
