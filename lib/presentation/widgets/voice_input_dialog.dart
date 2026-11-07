import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/voice_nlp_service.dart';
import '../../core/utils/jalali_helper.dart';
import '../../domain/models/reminder_model.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';

class VoiceInputDialog extends StatefulWidget {
  const VoiceInputDialog({super.key});

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog> {
  final TextEditingController _textController = TextEditingController();
  ParsedVoiceResult? _parsed;

  final List<String> _samplePhrases = [
    'فردا ساعت ۱۰ صبح جلسه بررسی خروجی APK',
    'امروز ساعت ۸ شب خرید نان تازه و شیر',
    'پس‌فردا ساعت ۵ بعد از ظهر ویزیت دکتر',
    'پنجشنبه ساعت ۹ صبح تمرین ورزشی',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.trim().isNotEmpty) {
      setState(() {
        _parsed = VoiceNlpService.instance.parsePersianVoiceText(text);
      });
    } else {
      setState(() {
        _parsed = null;
      });
    }
  }

  void _confirmAndCreate() {
    if (_parsed == null) return;

    final newReminder = ReminderModel(
      id: const Uuid().v4(),
      title: _parsed!.title,
      memo: 'ثبت شده با صوت: «${_textController.text}»',
      categoryId: 'work',
      priority: Priority.medium,
      jalaliYear: _parsed!.jalaliDate?.year,
      jalaliMonth: _parsed!.jalaliDate?.month,
      jalaliDay: _parsed!.jalaliDate?.day,
      hour: _parsed!.hour,
      minute: _parsed!.minute,
      createdAt: DateTime.now(),
    );

    context.read<ReminderBloc>().add(AddReminderEvent(newReminder));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.mic_rounded, color: AppColors.primaryBlueLight),
              SizedBox(width: 8),
              Text(
                'تایپ صوتی هوشمند (NLP فارسی)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'عنوان، تاریخ شمسی و ساعت به صورت خودکار از گفتار استخراج می‌شوند.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _textController,
            onChanged: _onTextChanged,
            decoration: InputDecoration(
              hintText: 'متن خود را بنویسید یا یکی از نمونه‌های زیر را انتخاب کنید...',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),

          // Preset testing chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _samplePhrases.map((phrase) {
              return ActionChip(
                label: Text(phrase, style: const TextStyle(fontSize: 11)),
                onPressed: () {
                  _textController.text = phrase;
                  _onTextChanged(phrase);
                },
              );
            }).toList(),
          ),

          if (_parsed != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x26388AF6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryBlueLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('عنوان: ${_parsed!.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (_parsed!.jalaliDate != null) ...[
                    const SizedBox(height: 4),
                    Text('تاریخ شمسی: ${JalaliHelper.formatJalali(_parsed!.jalaliDate!)}', style: const TextStyle(fontSize: 12)),
                  ],
                  if (_parsed!.hasTime && _parsed!.hour != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ساعت: ${JalaliHelper.toPersianDigits(_parsed!.hour.toString().padLeft(2, '0'))}:${JalaliHelper.toPersianDigits((_parsed!.minute ?? 0).toString().padLeft(2, '0'))}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _parsed != null ? _confirmAndCreate : null,
              icon: const Icon(Icons.check_rounded),
              label: const Text('تایید و ایجاد یادآور'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
