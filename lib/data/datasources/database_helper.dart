import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/models/reminder_model.dart';
import '../../domain/models/subtask_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shamsi_reminders.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Reminders Table
    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        memo TEXT,
        categoryId TEXT NOT NULL,
        priority TEXT NOT NULL,
        jalaliYear INTEGER,
        jalaliMonth INTEGER,
        jalaliDay INTEGER,
        hour INTEGER,
        minute INTEGER,
        recurrence TEXT NOT NULL,
        recurrenceInterval INTEGER DEFAULT 1,
        recurrenceDays TEXT,
        recurrenceEndDate TEXT,
        nextOccurrence TEXT,
        notificationId INTEGER,
        subtasksJson TEXT,
        isCompleted INTEGER NOT NULL,
        completedAt TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        isSnoozed INTEGER NOT NULL,
        snoozeUntil TEXT
      )
    ''');

    // 2. Relational Subtasks Table
    await db.execute('''
      CREATE TABLE subtasks (
        id TEXT PRIMARY KEY,
        reminder_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL,
        order_index INTEGER DEFAULT 0,
        FOREIGN KEY (reminder_id) REFERENCES reminders (id) ON DELETE CASCADE
      )
    ''');

    // 3. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        iconName TEXT NOT NULL
      )
    ''');

    // 4. App Settings Key-Value Table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Indexes for high performance
    await db.execute('CREATE INDEX idx_reminders_completed ON reminders(isCompleted)');
    await db.execute('CREATE INDEX idx_reminders_due ON reminders(jalaliYear, jalaliMonth, jalaliDay)');
    await db.execute('CREATE INDEX idx_subtasks_reminder ON subtasks(reminder_id)');

    // Seed default categories
    final defaultCategories = [
      {'id': 'work', 'name': 'کار', 'color': '#3B82F6', 'iconName': 'Briefcase'},
      {'id': 'personal', 'name': 'شخصی', 'color': '#10B981', 'iconName': 'User'},
      {'id': 'shopping', 'name': 'خرید', 'color': '#F59E0B', 'iconName': 'ShoppingCart'},
      {'id': 'health', 'name': 'سلامت', 'color': '#EF4444', 'iconName': 'Heart'},
      {'id': 'study', 'name': 'مطالعه', 'color': '#8B5CF6', 'iconName': 'BookOpen'},
    ];

    for (final cat in defaultCategories) {
      await db.insert('categories', cat);
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.transaction((txn) async {
        // Safely add missing columns to reminders if coming from v1
        final columns = [
          'recurrenceInterval INTEGER DEFAULT 1',
          'recurrenceDays TEXT',
          'recurrenceEndDate TEXT',
          'nextOccurrence TEXT',
          'notificationId INTEGER',
          'updatedAt TEXT',
          'snoozeUntil TEXT',
        ];

        for (final col in columns) {
          try {
            await txn.execute('ALTER TABLE reminders ADD COLUMN $col');
          } catch (_) {
            // Column may already exist
          }
        }

        // Create subtasks table
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS subtasks (
            id TEXT PRIMARY KEY,
            reminder_id TEXT NOT NULL,
            title TEXT NOT NULL,
            is_completed INTEGER NOT NULL,
            order_index INTEGER DEFAULT 0,
            FOREIGN KEY (reminder_id) REFERENCES reminders (id) ON DELETE CASCADE
          )
        ''');

        // Create categories table
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color TEXT NOT NULL,
            iconName TEXT NOT NULL
          )
        ''');

        // Create app_settings table
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        // Create indexes
        await txn.execute('CREATE INDEX IF NOT EXISTS idx_reminders_completed ON reminders(isCompleted)');
        await txn.execute('CREATE INDEX IF NOT EXISTS idx_reminders_due ON reminders(jalaliYear, jalaliMonth, jalaliDay)');
        await txn.execute('CREATE INDEX IF NOT EXISTS idx_subtasks_reminder ON subtasks(reminder_id)');

        // Migrate existing subtasksJson into subtasks table without data loss
        try {
          final existingRows = await txn.query('reminders', columns: ['id', 'subtasksJson']);
          for (final row in existingRows) {
            final reminderId = row['id'] as String;
            final rawJson = row['subtasksJson'] as String?;
            if (rawJson != null && rawJson.isNotEmpty) {
              try {
                final List decoded = jsonDecode(rawJson);
                int order = 0;
                for (final item in decoded) {
                  final map = item as Map<String, dynamic>;
                  await txn.insert('subtasks', {
                    'id': map['id'] ?? '${reminderId}_sub_$order',
                    'reminder_id': reminderId,
                    'title': map['title'] ?? '',
                    'is_completed': (map['isCompleted'] == true || map['isCompleted'] == 1) ? 1 : 0,
                    'order_index': order++,
                  }, conflictAlgorithm: ConflictAlgorithm.replace);
                }
              } catch (_) {}
            }
          }
        } catch (_) {}
      });
    }
  }

  Future<int> insertReminder(ReminderModel reminder) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final res = await txn.insert(
        'reminders',
        reminder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save relational subtasks
      await txn.delete('subtasks', where: 'reminder_id = ?', whereArgs: [reminder.id]);
      int order = 0;
      for (final st in reminder.subtasks) {
        await txn.insert('subtasks', {
          'id': st.id,
          'reminder_id': reminder.id,
          'title': st.title,
          'is_completed': st.isCompleted ? 1 : 0,
          'order_index': order++,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      return res;
    });
  }

  Future<List<ReminderModel>> getAllReminders() async {
    final db = await instance.database;
    final reminderRows = await db.query('reminders', orderBy: 'createdAt DESC');
    
    // Batch query subtasks for optimal performance
    final subtaskRows = await db.query('subtasks', orderBy: 'order_index ASC');
    final Map<String, List<SubTaskModel>> subtaskMap = {};
    for (final stRow in subtaskRows) {
      final remId = stRow['reminder_id'] as String;
      subtaskMap.putIfAbsent(remId, () => []).add(SubTaskModel.fromMap(stRow));
    }

    return reminderRows.map((json) {
      final remId = json['id'] as String;
      final explicitSubtasks = subtaskMap[remId];
      return ReminderModel.fromMap(json, explicitSubtasks: explicitSubtasks);
    }).toList();
  }

  Future<int> updateReminder(ReminderModel reminder) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final res = await txn.update(
        'reminders',
        reminder.toMap(),
        where: 'id = ?',
        whereArgs: [reminder.id],
      );

      await txn.delete('subtasks', where: 'reminder_id = ?', whereArgs: [reminder.id]);
      int order = 0;
      for (final st in reminder.subtasks) {
        await txn.insert('subtasks', {
          'id': st.id,
          'reminder_id': reminder.id,
          'title': st.title,
          'is_completed': st.isCompleted ? 1 : 0,
          'order_index': order++,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      return res;
    });
  }

  Future<int> deleteReminder(String id) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      await txn.delete('subtasks', where: 'reminder_id = ?', whereArgs: [id]);
      return await txn.delete('reminders', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// تهیه نسخه پشتیبان کامل از تمامی داده‌ها
  Future<Map<String, dynamic>> exportBackupData() async {
    final reminders = await getAllReminders();
    final db = await instance.database;
    final categories = await db.query('categories');
    final settings = await db.query('app_settings');

    return {
      'version': 2,
      'exportDate': DateTime.now().toIso8601String(),
      'reminders': reminders.map((r) => r.toMap()).toList(),
      'categories': categories,
      'app_settings': settings,
    };
  }

  /// بازیابی اتمیک نسخه پشتیبان با اعتبارسنجی و رول‌بک
  Future<bool> restoreBackupData(Map<String, dynamic> data) async {
    if (data['reminders'] == null || data['reminders'] is! List) {
      return false;
    }

    final db = await instance.database;
    return await db.transaction((txn) async {
      final List rawList = data['reminders'] as List;
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          final reminder = ReminderModel.fromMap(item);
          await txn.insert('reminders', reminder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

          if (reminder.subtasks.isNotEmpty) {
            await txn.delete('subtasks', where: 'reminder_id = ?', whereArgs: [reminder.id]);
            int order = 0;
            for (final st in reminder.subtasks) {
              await txn.insert('subtasks', {
                'id': st.id,
                'reminder_id': reminder.id,
                'title': st.title,
                'is_completed': st.isCompleted ? 1 : 0,
                'order_index': order++,
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }
      return true;
    });
  }
}
