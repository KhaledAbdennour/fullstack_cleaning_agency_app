import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mob_dev_project/l10n/app_localizations.dart';
import 'screens/onboarding_screen.dart';
import 'screens/homescreen.dart';
import 'screens/agency_dashboard_page.dart';
import 'screens/login.dart';
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
import 'logic/cubits/worker_active_jobs_cubit.dart';
import 'data/databases/database_seeder.dart';
import 'core/config/firebase_config.dart';
import 'core/services/locale_service.dart';
import 'core/di/service_locator.dart';
import 'data/repositories/notifications/notifications_repo.dart';
import 'logic/cubits/notifications/notifications_cubit.dart';
import 'core/services/notification_router.dart';
import 'core/navigation/app_navigator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/debug/debug_logger.dart';
import 'core/services/crashlytics_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    try {
      try {
        Firebase.app();
      } catch (_) {
        await Firebase.initializeApp();
      }

      await FirebaseConfig.initialize();

      await CrashlyticsService.initialize();

      DatabaseSeeder.seedDatabase().catchError((e, stackTrace) {
        debugPrint('Database seeding error: $e');
        CrashlyticsService.recordError(e, stackTrace,
            reason: 'Database seeding failed');
      });
    } catch (e, stackTrace) {
      debugPrint('Firebase/Firestore initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      if (FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled) {
        CrashlyticsService.recordError(e, stackTrace,
            reason: 'Firebase initialization failed', fatal: false);
      }
    }
  }

  setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

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

  void changeLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    await LocaleService.saveLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeLoaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
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
        BlocProvider(create: (context) => WorkerActiveJobsCubit()),
        BlocProvider(
          create: (context) =>
              NotificationsCubit(getIt<AbstractNotificationsRepo>()),
        ),
      ],
      child: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'CleanSpace',
          debugShowCheckedModeBanner: false,
          locale: _locale,
          theme: ThemeData(primarySwatch: Colors.teal),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleService.supportedLocales,
          home: const _CheckAuthScreen(),
          builder: (context, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NotificationRouter.markAppReady();
              NotificationRouter.handleInitialMessage();
            });

            FirebaseMessaging.onMessageOpenedApp.listen((message) {
              NotificationRouter.handleMessage(message);
            });

            return child!;
          },
        ),
      ),
    );
  }
}

class _CheckAuthScreen extends StatefulWidget {
  const _CheckAuthScreen();

  @override
  State<_CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends State<_CheckAuthScreen> {
  bool _checked = false;
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    DebugLogger.log(
      '_CheckAuthScreen',
      '_checkAuth_START',
      data: {
        'hypothesisId': 'H3',
        'sessionId': 'debug-session',
        'runId': 'run1',
      },
    );

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    final currentUserId = prefs.getInt('current_user_id');
    DebugLogger.log(
      '_CheckAuthScreen',
      '_checkAuth_SHAREDPREFS',
      data: {
        'hypothesisId': 'H4',
        'currentUserId': currentUserId,
        'hasSeenOnboarding': hasSeenOnboarding,
        'sessionId': 'debug-session',
        'runId': 'run1',
      },
    );

    final profilesCubit = context.read<ProfilesCubit>();
    await profilesCubit.loadCurrentUser();

    if (mounted) {
      setState(() {
        _hasSeenOnboarding = hasSeenOnboarding;
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocBuilder<ProfilesCubit, ProfilesState>(
      buildWhen: (previous, current) {
        if (previous.runtimeType == current.runtimeType) {
          if (previous is ProfilesLoaded && current is ProfilesLoaded) {
            final prevUser = previous.currentUser?['id'];
            final currUser = current.currentUser?['id'];
            return prevUser != currUser;
          }
          return false;
        }
        return true;
      },
      builder: (context, state) {
        DebugLogger.log(
          '_CheckAuthScreen',
          'BUILD_DECISION_START',
          data: {
            'hypothesisId': 'H3',
            'stateType': state.runtimeType.toString(),
            'isProfilesLoaded': state is ProfilesLoaded,
            'hasCurrentUser':
                state is ProfilesLoaded && (state).currentUser != null,
            'hasSeenOnboarding': _hasSeenOnboarding,
            'sessionId': 'debug-session',
            'runId': 'run1',
          },
        );

        if (state is ProfilesLoaded && state.currentUser != null) {
          final userType =
              (state.currentUser!['user_type'] as String? ?? '').trim();

          DebugLogger.log(
            '_CheckAuthScreen',
            'USER_LOGGED_IN',
            data: {
              'hypothesisId': 'H3',
              'userType': userType,
              'sessionId': 'debug-session',
              'runId': 'run1',
            },
          );

          if (userType == 'Client') {
            return const HomeScreen(key: ValueKey('client_home'));
          }

          if (userType == 'Agency' || userType == 'Individual Cleaner') {
            return const AgencyDashboardPage();
          }
        }

        DebugLogger.log(
          '_CheckAuthScreen',
          'NOT_LOGGED_IN_DECISION',
          data: {
            'hypothesisId': 'H3',
            'hypothesisId2': 'H4',
            'hasSeenOnboarding': _hasSeenOnboarding,
            'willShowOnboarding': _hasSeenOnboarding == false,
            'willShowLogin': _hasSeenOnboarding == true,
            'sessionId': 'debug-session',
            'runId': 'run1',
          },
        );

        if (_hasSeenOnboarding == true) {
          return const Login();
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }
}
