import 'dart:async';
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
import 'firebase_options.dart';
import 'screens/main_menu_screen.dart';
import 'cubits/game/game_cubit.dart';
import 'cubits/settings/settings_cubit.dart';
import 'cubits/settings/settings_state.dart';
import 'services/app_localizations.dart';
import 'services/sound_service.dart';
import 'config/app_config.dart';
import 'widgets/loading_screen_widget.dart';

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
  try {
    await SoundService().initialize().timeout(
      const Duration(seconds: 2),
    );
    _logger.i('SoundService initialized successfully');
  } on TimeoutException {
    _logger.e('SoundService initialization timed out - sounds may not work');
  } catch (e) {
    _logger.e('SoundService initialization failed', error: e);
  }

  // CRITICAL FIX: Initialize SettingsCubit before running app to ensure state is ready
  // This prevents GameCubit from accessing uninitialized settings
  //
  // BUG FIX: Previously used `onTimeout` callback which returns void and doesn't throw,
  // causing the code to continue as if initialization completed even when it timed out.
  // Now we properly catch TimeoutException to detect when initialization didn't complete.
  final settingsCubit = SettingsCubit();

  try {
    // Wait for initialization to complete (with timeout)
    // If timeout occurs, TimeoutException is thrown (not silently swallowed)
    await settingsCubit.initialize().timeout(
          const Duration(seconds: 5),
        );
    _logger.i('SettingsCubit initialization completed successfully');
  } on TimeoutException catch (e) {
    // CRITICAL: Timeout occurred - initialization didn't complete
    // This means settingsCubit.state still has default values from SettingsState.initial()
    // GameCubit constructor will read these defaults, which is safe but not ideal
    // Initialization may complete later in background, but state won't sync to GameCubit
    _logger.w(
        'SettingsCubit initialization timed out after 5 seconds - GameCubit will use default settings',
        error: e);
  } catch (e) {
    // Other initialization errors (network, permissions, etc.)
    _logger.e(
        'SettingsCubit initialization failed - GameCubit will use default settings',
        error: e);
    // Continue with defaults - SettingsState.initial() provides safe defaults
  }

  // Note: If initialization timed out or failed, GameCubit will use default sound/haptics settings
  // from SettingsState.initial(). This is safe but may not match user's saved preferences.
  // Settings will be correct once initialization completes and user navigates away and back.

  // CRITICAL: settingsCubit is now initialized - pass it to app
  // It will NOT be initialized again in BlockerinoApp to avoid double initialization
  runApp(
    BlockerinoApp(preInitializedSettingsCubit: settingsCubit),
  );
}

class BlockerinoApp extends StatelessWidget {
  final SettingsCubit? preInitializedSettingsCubit;

  const BlockerinoApp({super.key, this.preInitializedSettingsCubit});

  @override
  Widget build(BuildContext context) {
    // Firebase Analytics instance (only if initialized)
    final analytics = _firebaseInitialized ? FirebaseAnalytics.instance : null;
    final observer = analytics != null
        ? FirebaseAnalyticsObserver(analytics: analytics)
        : null;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          // CRITICAL FIX: preInitializedSettingsCubit is always provided from main()
          // and has already been initialized and awaited. We use it directly without
          // calling initialize() again to avoid concurrent initialization, race conditions,
          // and duplicate state emissions.
          //
          // Original bug: The cascade operator `..initialize()` in the fallback expression
          // could theoretically execute if preInitializedSettingsCubit is null, but more
          // importantly, it's confusing and could lead to double initialization if the
          // logic changes. This explicit check ensures we never call initialize() on an
          // already-initialized cubit.
          value: preInitializedSettingsCubit ??
              // Defensive fallback (should never execute in normal flow)
              // CRITICAL FIX: Do not call initialize() here - we cannot await in this synchronous context.
              // If this fallback executes, the cubit will use default values from SettingsState.initial().
              // This is acceptable for a defensive fallback that should never execute.
              SettingsCubit(),
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
                // Show loading screen initially, then transition to main menu
                home: const _InitialLoadingScreen(),
              );
            },
          );
        },
      ),
    );
  }
}

/// Initial loading screen that shows during app startup
/// Displays KR Studio logo while app initializes
class _InitialLoadingScreen extends StatefulWidget {
  const _InitialLoadingScreen();

  @override
  State<_InitialLoadingScreen> createState() => _InitialLoadingScreenState();
}

class _InitialLoadingScreenState extends State<_InitialLoadingScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Show loading screen for a minimum duration for better UX
    // This ensures users see the KR Studio logo
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const LoadingScreenWidget(
        message: 'Starting Blockerino...',
      );
    }

    return const MainMenuScreen();
  }
}
