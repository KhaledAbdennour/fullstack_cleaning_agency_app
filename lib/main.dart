import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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
  
  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    print('Warning: Supabase initialization failed: $e');
    print('Make sure to set SUPABASE_URL and SUPABASE_ANON_KEY environment variables');
  }
  
  // Initialize notifications
  try {
    await NotificationService.initialize();
  } catch (e) {
    print('Warning: Notification initialization failed: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
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

  void _changeLocale(Locale locale) async {
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
