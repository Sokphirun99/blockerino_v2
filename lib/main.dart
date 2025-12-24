import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:device_preview/device_preview.dart';
import 'firebase_options.dart';
import 'screens/main_menu_screen.dart';
import 'cubits/game/game_cubit.dart';
import 'cubits/settings/settings_cubit.dart';
import 'cubits/settings/settings_state.dart';
import 'services/app_localizations.dart';
import 'services/sound_service.dart';
import 'config/app_config.dart';

// Global flag to track Firebase initialization
bool _firebaseInitialized = false;
final Logger _logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firebaseInitialized = true;

    // Initialize Firebase Crashlytics only if Firebase initialized successfully
    try {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
    } catch (crashlyticsError) {
      _logger.w('Crashlytics setup failed', error: crashlyticsError);
    }
  } catch (e) {
    _logger.e('Firebase initialization failed', error: e);
    _logger.w('App will run without Firebase features');
    _firebaseInitialized = false;
  }

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize sound service with timeout to prevent blocking app startup
  // If initialization takes too long, app will start anyway and sounds will initialize lazily
  SoundService().initialize().timeout(
    const Duration(seconds: 2),
    onTimeout: () {
      _logger.w('SoundService initialization timed out - sounds may not work');
    },
  ).catchError((e) {
    _logger.e('SoundService initialization failed', error: e);
  });

  runApp(
    DevicePreview(
      enabled: kDebugMode, // Only enable in debug mode
      builder: (context) => const BlockerinoApp(),
    ),
  );
}

class BlockerinoApp extends StatelessWidget {
  const BlockerinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Firebase Analytics instance (only if initialized)
    final analytics = _firebaseInitialized ? FirebaseAnalytics.instance : null;
    final observer = analytics != null
        ? FirebaseAnalyticsObserver(analytics: analytics)
        : null;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              SettingsCubit()..initialize(), // Initialize settings on creation
        ),
        BlocProvider(
          create: (context) => GameCubit(
            settingsCubit: context.read<SettingsCubit>(),
          ),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return ScreenUtilInit(
            // Design size - using iPhone 11 Pro as reference (375x812)
            // This ensures consistent scaling across all devices and aspect ratios
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return DevicePreview.appBuilder(
                context,
                MaterialApp(
                  title: 'Blockerino',
                  debugShowCheckedModeBanner: false,
                  navigatorObservers: observer != null ? [observer] : [],

                  // Localization support
                  // Use DevicePreview's locale in debug mode, otherwise use settings
                  locale: DevicePreview.locale(context) ??
                      settingsState.currentLocale,
                  supportedLocales: AppConfig.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],

                  theme: ThemeData(
                    brightness: Brightness.dark,
                    scaffoldBackgroundColor: Colors.black,
                    primarySwatch: Colors.blue,
                    textTheme: GoogleFonts.pressStart2pTextTheme(
                      ThemeData.dark().textTheme,
                    ),
                  ),
                  home: const MainMenuScreen(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
