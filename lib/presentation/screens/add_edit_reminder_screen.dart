import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/jalali_helper.dart';
import '../../domain/models/reminder_model.dart';
import '../../domain/models/subtask_model.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';

class AddEditReminderScreen extends StatefulWidget {
  final ReminderModel? reminder;

  const AddEditReminderScreen({super.key, this.reminder});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtaskInputController;

  late Priority _priority;
  late RecurrenceType _recurrence;
  bool _hasDueDate = false;
  late Jalali _jalaliDate;
  int _hour = 10;
  int _minute = 0;
  List<SubTaskModel> _subtasks = [];

  @override
  void initState() {
    super.initState();
    final rem = widget.reminder;
    _titleController = TextEditingController(text: rem?.title ?? '');
    _subtaskInputController = TextEditingController();

    _priority = rem?.priority ?? Priority.none;
    _recurrence = rem?.recurrence ?? RecurrenceType.none;
    _subtasks = rem != null ? List<SubTaskModel>.from(rem.subtasks) : [];

    if (rem != null && rem.hasDueDate) {
      _hasDueDate = true;
      _jalaliDate = Jalali(rem.jalaliYear!, rem.jalaliMonth!, rem.jalaliDay!);
      _hour = rem.hour ?? 10;
      _minute = rem.minute ?? 0;
    } else {
      _jalaliDate = Jalali.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtaskInputController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final text = _subtaskInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subtasks.add(SubTaskModel(
          id: const Uuid().v4(),
          title: text,
          isCompleted: false,
        ));
        _subtaskInputController.clear();
      });
    }
  }

  Future<void> _pickJalaliDate(BuildContext context) async {
    int tempYear = _jalaliDate.year;
    int tempMonth = _jalaliDate.month;
    int tempDay = _jalaliDate.day;

    final months = [
      'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
      'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
    ];

    final result = await showDialog<Jalali>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final daysInMonth = Jalali(tempYear, tempMonth, 1).monthLength;
            if (tempDay > daysInMonth) tempDay = daysInMonth;

            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('انتخاب تاریخ شمسی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Year
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
                      // Month
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
                  // Day
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
                  const SizedBox(height: 14),
                  // Quick selection chips
                  Wrap(
                    spacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('امروز', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          final now = Jalali.now();
                          setDialogState(() {
                            tempYear = now.year;
                            tempMonth = now.month;
                            tempDay = now.day;
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('فردا', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          final tmrw = Jalali.now().addDays(1);
                          setDialogState(() {
                            tempYear = tmrw.year;
                            tempMonth = tmrw.month;
                            tempDay = tmrw.day;
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('پس‌فردا', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          final afterTmrw = Jalali.now().addDays(2);
                          setDialogState(() {
                            tempYear = afterTmrw.year;
                            tempMonth = afterTmrw.month;
                            tempDay = afterTmrw.day;
                          });
                        },
                      ),
                    ],
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
                  child: const Text('تایید تاریخ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _jalaliDate = result;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final reminderToSave = ReminderModel(
      id: widget.reminder?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      memo: null,
      categoryId: 'default',
      priority: _priority,
      jalaliYear: _hasDueDate ? _jalaliDate.year : null,
      jalaliMonth: _hasDueDate ? _jalaliDate.month : null,
      jalaliDay: _hasDueDate ? _jalaliDate.day : null,
      hour: _hasDueDate ? _hour : null,
      minute: _hasDueDate ? _minute : null,
      recurrence: _recurrence,
      subtasks: _subtasks,
      isCompleted: widget.reminder?.isCompleted ?? false,
      completedAt: widget.reminder?.completedAt,
      createdAt: widget.reminder?.createdAt ?? DateTime.now(),
    );

    if (widget.reminder == null) {
      context.read<ReminderBloc>().add(AddReminderEvent(reminderToSave));
    } else {
      context.read<ReminderBloc>().add(UpdateReminderEvent(reminderToSave));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reminder != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'ویرایش یادآور' : 'ایجاد یادآور جدید'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('ذخیره', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title input
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'عنوان یادآور',
                hintText: 'چه کاری را باید یادآوری کنیم؟',
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'لطفاً عنوان یادآور را بنویسید' : null,
            ),
            const SizedBox(height: 16),

            // Jalali Due Date & Time Section (بخش تاریخ و ساعت سررسید شمسی)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تاریخ و ساعت سررسید (تقویم شمسی)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    value: _hasDueDate,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (val) => setState(() => _hasDueDate = val),
                  ),
                  if (_hasDueDate) ...[
                    const Divider(color: AppColors.divider),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primaryBlueLight),
                      title: Text(
                        JalaliHelper.formatJalali(_jalaliDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Text('تغییر تاریخ', style: TextStyle(color: AppColors.primaryBlueLight, fontSize: 12, fontWeight: FontWeight.bold)),
                      onTap: () => _pickJalaliDate(context),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time_rounded, color: AppColors.primaryBlueLight),
                      title: Text(
                        'ساعت ${JalaliHelper.toPersianDigits(_hour.toString().padLeft(2, '0'))}:${JalaliHelper.toPersianDigits(_minute.toString().padLeft(2, '0'))}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Text('تغییر ساعت', style: TextStyle(color: AppColors.primaryBlueLight, fontSize: 12, fontWeight: FontWeight.bold)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: _hour, minute: _minute),
                        );
                        if (time != null) {
                          setState(() {
                            _hour = time.hour;
                            _minute = time.minute;
                          });
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // SubTasks Checklist: بلافاصله زیر بخش تاریخ و زمان
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'چک‌لیست زیرمجموعه‌ها (${JalaliHelper.toPersianDigits(_subtasks.length)})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskInputController,
                          decoration: InputDecoration(
                            hintText: 'افزودن مورد به چک‌لیست...',
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onSubmitted: (_) => _addSubtask(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addSubtask,
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                      ),
                    ],
                  ),
                  if (_subtasks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._subtasks.map((st) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.circle, size: 8, color: AppColors.primaryBlueLight),
                        title: Text(st.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                          onPressed: () => setState(() => _subtasks.removeWhere((s) => s.id == st.id)),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
