import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/jalali_helper.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';

class SnoozeBottomSheet extends StatelessWidget {
  final String reminderId;

  const SnoozeBottomSheet({super.key, required this.reminderId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'به تعویق انداختن (Snooze)',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),

          _buildOption(context, '۵ دقیقه دیگر', 5),
          _buildOption(context, '۱۵ دقیقه دیگر', 15),
          _buildOption(context, '۳۰ دقیقه دیگر', 30),
          _buildOption(context, '۱ ساعت دیگر', 60),
          _buildOption(context, '۲ ساعت دیگر', 120),
          const Divider(color: AppColors.divider),
          _buildCustomPickerOption(context),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String label, int minutes) {
    return ListTile(
      leading: const Icon(Icons.timer_outlined, color: AppColors.primaryBlue),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      onTap: () {
        final now = DateTime.now().add(Duration(minutes: minutes));
        context.read<ReminderBloc>().add(SnoozeReminderEvent(
          reminderId: reminderId,
          newHour: now.hour,
          newMinute: now.minute,
        ));
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCustomPickerOption(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.edit_calendar_rounded, color: AppColors.primaryBlueLight),
      title: const Text('انتخاب زمان دلخواه (تقویم شمسی)', style: TextStyle(color: AppColors.primaryBlueLight, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryBlueLight),
      onTap: () async {
        final now = Jalali.now();
        int tempYear = now.year;
        int tempMonth = now.month;
        int tempDay = now.day;

        final months = [
          'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
          'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
        ];

        final pickedDate = await showDialog<Jalali>(
          context: context,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (dialogCtx, setDialogState) {
                final daysInMonth = Jalali(tempYear, tempMonth, 1).monthLength;
                if (tempDay > daysInMonth) tempDay = daysInMonth;

                return AlertDialog(
                  backgroundColor: AppColors.card,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('انتخاب تاریخ تعویق (شمسی)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: tempYear,
                              decoration: InputDecoration(
                                labelText: 'سال',
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: JalaliHelper.getSupportedYears().map((y) {
                                return DropdownMenuItem(value: y, child: Text(JalaliHelper.toPersianDigits(y.toString())));
                              }).toList(),
                              onChanged: (y) {
                                if (y != null) setDialogState(() => tempYear = y);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: tempMonth,
                              decoration: InputDecoration(
                                labelText: 'ماه',
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: List.generate(12, (i) {
                                return DropdownMenuItem(value: i + 1, child: Text(months[i], style: const TextStyle(fontSize: 13)));
                              }),
                              onChanged: (m) {
                                if (m != null) setDialogState(() => tempMonth = m);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: tempDay,
                        decoration: InputDecoration(
                          labelText: 'روز',
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: List.generate(daysInMonth, (i) {
                          final d = i + 1;
                          return DropdownMenuItem(value: d, child: Text('روز ${JalaliHelper.toPersianDigits(d.toString())}'));
                        }),
                        onChanged: (d) {
                          if (d != null) setDialogState(() => tempDay = d);
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('انصراف'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, Jalali(tempYear, tempMonth, tempDay)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('مرحله بعد (ساعت)'),
                    ),
                  ],
                );
              },
            );
          },
        );

        if (pickedDate == null || !context.mounted) return;

        final pickedTime = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 12, minute: 0),
        );

        if (pickedTime == null || !context.mounted) return;

        context.read<ReminderBloc>().add(SnoozeReminderEvent(
          reminderId: reminderId,
          newHour: pickedTime.hour,
          newMinute: pickedTime.minute,
          newJalaliYear: pickedDate.year,
          newJalaliMonth: pickedDate.month,
          newJalaliDay: pickedDate.day,
        ));

        Navigator.pop(context);
      },
    );
  }
}
