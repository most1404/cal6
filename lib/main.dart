import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/services/notification_service.dart';
import 'core/services/widget_service.dart';
import 'data/datasources/database_helper.dart';
import 'presentation/bloc/reminder_bloc.dart';
import 'presentation/bloc/reminder_event.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local SQLite Database
  await DatabaseHelper.instance.database;

  // Initialize Local Notifications with Snooze and Done Actions
  await NotificationService.instance.init();

  // Initialize Home Screen Widget listener
  await WidgetService.instance.init();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ShamsiReminderApp());
}

class ShamsiReminderApp extends StatelessWidget {
  const ShamsiReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReminderBloc()..add(const LoadRemindersEvent()),
      child: MaterialApp(
        title: 'یادآور شمسی',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F1218),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF388AF6), // Samsung One UI Electric Blue
            secondary: Color(0xFF10B981),
            surface: Color(0xFF171B24),
            error: Color(0xFFEF4444),
          ),
          cardTheme: const CardTheme(
            color: Color(0xFF1C222E),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F1218),
            elevation: 0,
            centerTitle: false,
          ),
        ),
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [
          Locale('fa', 'IR'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const HomeScreen(),
      ),
    );
  }
}

/// Type alias to support default Flutter test templates
typedef MyApp = ShamsiReminderApp;
