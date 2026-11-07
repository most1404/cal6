import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/jalali_helper.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_state.dart';
import '../widgets/reminder_card.dart';
import '../widgets/voice_input_dialog.dart';
import 'add_edit_reminder_screen.dart';
import 'completed_reminders_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todayJalali = JalaliHelper.now();
    final todayTitle = JalaliHelper.formatJalali(todayJalali);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Samsung One UI Large Expanding Header
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
                title: const Text(
                  'یادآور',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
                background: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        todayTitle,
                        style: const TextStyle(
                          color: AppColors.primaryBlueLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      BlocBuilder<ReminderBloc, ReminderState>(
                        builder: (context, state) {
                          final count = state.activeReminders.length;
                          return Text(
                            '${JalaliHelper.toPersianDigits(count)} یادآور فعال',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: AppColors.textSecondary),
                  tooltip: 'انجام‌شده‌ها',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CompletedRemindersScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                  tooltip: 'تنظیمات',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),

            // Reminders List grouped by Shamsi Time
            BlocBuilder<ReminderBloc, ReminderState>(
              builder: (context, state) {
                final list = state.activeReminders;
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all_rounded, size: 64, color: AppColors.textMuted),
                          SizedBox(height: 16),
                          Text(
                            'هیچ یادآور فعالی وجود ندارد',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final reminder = list[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ReminderCard(reminder: reminder),
                        );
                      },
                      childCount: list.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // Floating Action Buttons: Smart Voice Reminder & Manual Create
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'voice_btn',
            backgroundColor: AppColors.cardHover,
            foregroundColor: AppColors.primaryBlueLight,
            elevation: 3,
            tooltip: 'تایپ صوتی هوشمند',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const VoiceInputDialog(),
              );
            },
            child: const Icon(Icons.mic_rounded),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'add_btn',
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: const Text('یادآور جدید', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditReminderScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
