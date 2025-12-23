import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';
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

  // Initialize sound service
  await SoundService().initialize();

  runApp(const BlockerinoApp());
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
        BlocProvider(create: (_) => SettingsCubit()),
        BlocProvider(
          create: (context) => GameCubit(
            settingsCubit: context.read<SettingsCubit>(),
          ),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            title: 'Blockerino',
            debugShowCheckedModeBanner: false,
            navigatorObservers: observer != null ? [observer] : [],

            // Localization support
            locale: settingsState.currentLocale,
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
          );
        },
      ),
    );
  }
}
