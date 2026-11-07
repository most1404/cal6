import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/widget_service.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';
import '../bloc/reminder_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تنظیمات برنامه'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_size_rounded, color: AppColors.primaryBlue),
                    SizedBox(width: 10),
                    Text(
                      'اندازه فونت ویجت هوماسکرین',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'این تنظیم فقط بر روی نوشته‌های ویجت صفحه اصلی گوشی اعمال شده و فوراً به روز می‌شود.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                BlocBuilder<ReminderBloc, ReminderState>(
                  builder: (context, state) {
                    final current = state.widgetFontSize;
                    return Row(
                      children: [
                        _buildFontSizeOption(
                          context: context,
                          label: 'کوچک',
                          subLabel: '۱۲ sp',
                          size: WidgetFontSize.small,
                          isSelected: current == WidgetFontSize.small,
                        ),
                        const SizedBox(width: 8),
                        _buildFontSizeOption(
                          context: context,
                          label: 'متوسط',
                          subLabel: '۱۴ sp',
                          size: WidgetFontSize.medium,
                          isSelected: current == WidgetFontSize.medium,
                        ),
                        const SizedBox(width: 8),
                        _buildFontSizeOption(
                          context: context,
                          label: 'بزرگ',
                          subLabel: '۱۷ sp',
                          size: WidgetFontSize.large,
                          isSelected: current == WidgetFontSize.large,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'عمومی و اعلان‌ها',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('صدای زنگ یادآور', style: TextStyle(fontSize: 14)),
                  value: true,
                  activeColor: AppColors.primaryBlue,
                  onChanged: (val) {},
                ),
                const Divider(color: AppColors.divider),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('لرزش (ویبره)', style: TextStyle(fontSize: 14)),
                  value: true,
                  activeColor: AppColors.primaryBlue,
                  onChanged: (val) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeOption({
    required BuildContext context,
    required String label,
    required String subLabel,
    required WidgetFontSize size,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<ReminderBloc>().add(ChangeWidgetFontSizeEvent(size));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('اندازه فونت ویجت به حالت «$label» تغییر یافت.'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0x26388AF6) : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? AppColors.primaryBlue : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
