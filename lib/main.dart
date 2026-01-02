import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mob_dev_project/l10n/app_localizations.dart';
import 'screens/onboarding_screen.dart';
import 'logic/cubits/profiles_cubit.dart';
import 'logic/cubits/agency_dashboard_cubit.dart';
import 'logic/cubits/listings_cubit.dart';
import 'logic/cubits/search_cubit.dart';
import 'logic/cubits/client_bookings_cubit.dart';
import 'logic/cubits/available_jobs_cubit.dart';
import 'logic/cubits/cleaner_history_cubit.dart';
import 'logic/cubits/cleaner_reviews_cubit.dart';
import 'logic/cubits/client_jobs_cubit.dart';
import 'logic/cubits/job_applications_cubit.dart';
import 'data/databases/dbhelper.dart';
import 'data/databases/database_seeder.dart';
import 'utils/role_based_home.dart';
import 'core/config/supabase_config.dart';
import 'core/services/notification_service.dart';
import 'core/services/locale_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite for desktop platforms (keeping for backward compatibility)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Initialize database (keeping for backward compatibility)
  await DBHelper.initialize();
  
  // Seed database with dummy data (keeping for backward compatibility)
  await DatabaseSeeder.seedDatabase();
  
  // Initialize Firebase Core (only on Android/iOS - not supported on Windows/desktop)
  print('═══════════════════════════════════════');
  print('🔍 DEBUG: Checking platform for Firebase...');
  print('🔍 DEBUG: Platform: ${Platform.operatingSystem}');
  print('═══════════════════════════════════════');
  
  // #region agent log
  try {
    final logPath = r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log';
    final logDir = Directory(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor');
    if (!logDir.existsSync()) {
      logDir.createSync(recursive: true);
      print('🔍 DEBUG: Created log directory');
    }
    final logFile = File(logPath);
    final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"A","location":"main.dart:47","message":"Checking platform for Firebase","data":{"platform":Platform.operatingSystem,"isAndroid":Platform.isAndroid,"isIOS":Platform.isIOS,"isWindows":Platform.isWindows},"timestamp":DateTime.now().millisecondsSinceEpoch});
    logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
    print('🔍 DEBUG: Log written successfully');
  } catch (e) {
    print('❌ DEBUG: Log write failed: $e');
  }
  // #endregion
  
  // Firebase only works on Android/iOS, skip on Windows/desktop
  if (Platform.isAndroid || Platform.isIOS) {
    print('🔍 DEBUG: Platform supports Firebase (Android/iOS)');
    // Check if Firebase apps already exist
    try {
      final existingApps = Firebase.apps;
      print('🔍 DEBUG: Existing Firebase apps count: ${existingApps.length}');
      if (existingApps.isNotEmpty) {
        print('✅ DEBUG: Firebase already initialized, skipping');
        for (final app in existingApps) {
          print('   - App: ${app.name}, Project: ${app.options.projectId}');
        }
      } else {
        print('🔍 DEBUG: No existing Firebase apps, will initialize');
      }
    } catch (e) {
      print('❌ DEBUG: Error checking Firebase apps: $e');
    }
    
    try {
      print('🔍 DEBUG: Calling Firebase.initializeApp()...');
      FirebaseApp app;
      try {
        // Try to get default app first
        app = Firebase.app();
        print('🔍 DEBUG: Default Firebase app already exists');
      } catch (e) {
        // If no default app exists, initialize it
        print('🔍 DEBUG: No default app found, initializing...');
        app = await Firebase.initializeApp();
      }
      print('═══════════════════════════════════════');
      print('✅ Firebase initialized successfully!');
      print('   App name: ${app.name}');
      print('   Project ID: ${app.options.projectId}');
      if (app.options.apiKey.isNotEmpty) {
        print('   API Key: ${app.options.apiKey.substring(0, 20)}...');
      }
      print('═══════════════════════════════════════');
      // #region agent log
      try {
        final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
        final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"A","location":"main.dart:85","message":"Firebase initialized successfully","data":{"appName":app.name,"projectId":app.options.projectId},"timestamp":DateTime.now().millisecondsSinceEpoch});
        logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
      } catch (e) {
        print('❌ DEBUG: Log write failed: $e');
      }
      // #endregion
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════');
      print('❌ Firebase initialization FAILED!');
      print('   Error: $e');
      print('   Type: ${e.runtimeType}');
      print('═══════════════════════════════════════');
      print('Full stack trace:');
      print(stackTrace);
      print('═══════════════════════════════════════');
      // #region agent log
      try {
        final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
        final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"A","location":"main.dart:98","message":"Firebase initialization failed","data":{"error":e.toString(),"errorType":e.runtimeType.toString()},"timestamp":DateTime.now().millisecondsSinceEpoch});
        logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
      } catch (logErr) {
        print('❌ DEBUG: Log write failed: $logErr');
      }
      // #endregion
      // Don't throw - allow app to continue even if Firebase fails
    }
  } else {
    print('⚠️  DEBUG: Firebase not supported on ${Platform.operatingSystem}');
    print('   Firebase will only work on Android/iOS devices');
    print('   To test Firebase, run on Android emulator or device');
    // #region agent log
    try {
      final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
      final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"A","location":"main.dart:110","message":"Firebase skipped - platform not supported","data":{"platform":Platform.operatingSystem},"timestamp":DateTime.now().millisecondsSinceEpoch});
      logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
    } catch (e) {
      print('❌ DEBUG: Log write failed: $e');
    }
    // #endregion
  }
  
  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    print('Warning: Supabase initialization failed: $e');
    print('Make sure to set SUPABASE_URL and SUPABASE_ANON_KEY environment variables');
  }
  
  // Initialize notifications (only on Android/iOS - not supported on Windows/desktop)
  if (Platform.isAndroid || Platform.isIOS) {
    print('🔍 DEBUG: Starting NotificationService initialization...');
  // #region agent log
  try {
    final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
    final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"B","location":"main.dart:62","message":"Starting NotificationService initialization","data":{},"timestamp":DateTime.now().millisecondsSinceEpoch});
    logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
  } catch (e) {
    print('🔍 DEBUG: Log write failed: $e');
  }
  // #endregion
  try {
    await NotificationService.initialize();
    print('✅ NotificationService initialized successfully');
    // #region agent log
    try {
      final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
      final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"B","location":"main.dart:69","message":"NotificationService initialized successfully","data":{},"timestamp":DateTime.now().millisecondsSinceEpoch});
      logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
    } catch (e) {
      print('🔍 DEBUG: Log write failed: $e');
    }
    // #endregion
  } catch (e, stackTrace) {
    print('❌ Warning: Notification initialization failed: $e');
    print('Stack trace: $stackTrace');
    // #region agent log
    try {
      final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
      final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"B","location":"main.dart:77","message":"NotificationService initialization failed","data":{"error":e.toString(),"errorType":e.runtimeType.toString()},"timestamp":DateTime.now().millisecondsSinceEpoch});
      logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
    } catch (logErr) {
      print('🔍 DEBUG: Log write failed: $logErr');
    }
    // #endregion
  }
  } else {
    print('⚠️  DEBUG: Notifications skipped - not supported on ${Platform.operatingSystem}');
    print('   Notifications will only work on Android/iOS devices');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
  
  // Expose method for settings page
  static _MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>();
  }
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', '');
  bool _localeLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final savedLocale = await LocaleService.getSavedLocale();
    if (savedLocale != null && mounted) {
      setState(() {
        _locale = savedLocale;
        _localeLoaded = true;
      });
    } else {
      setState(() {
        _localeLoaded = true;
      });
    }
  }

  // Public method for settings page to change locale
  void changeLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    await LocaleService.saveLocale(locale);
  }

  // Expose method for settings page
  static _MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>();
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeLoaded) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final isRTL = LocaleService.isRTL(_locale);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ProfilesCubit()),
        BlocProvider(create: (context) => ActiveListingsCubit()),
        BlocProvider(create: (context) => PastBookingsCubit()),
        BlocProvider(create: (context) => CleanerTeamCubit()),
        BlocProvider(create: (context) => ListingsCubit()),
        BlocProvider(create: (context) => SearchCubit()),
        BlocProvider(create: (context) => ClientBookingsCubit()),
        BlocProvider(create: (context) => AvailableJobsCubit()),
        BlocProvider(create: (context) => CleanerHistoryCubit()),
        BlocProvider(create: (context) => CleanerReviewsCubit()),
        BlocProvider(create: (context) => ClientJobsCubit()),
        BlocProvider(create: (context) => JobApplicationsCubit()),
      ],
      child: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: MaterialApp(
          title: 'CleanSpace',
          debugShowCheckedModeBanner: false,
          locale: _locale,
          theme: ThemeData(
            primarySwatch: Colors.teal,
          ),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleService.supportedLocales,
          home: const OnboardingScreen(),
        ),
      ),
    );
  }
}
