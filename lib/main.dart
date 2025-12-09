import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'screens/main_menu_screen.dart';
import 'providers/game_state_provider.dart';
import 'providers/settings_provider.dart';
import 'services/app_localizations.dart';
import 'config/app_config.dart';

// Global flag to track Firebase initialization
bool _firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firebaseInitialized = true;
    
    // Initialize Firebase Crashlytics only if Firebase initialized successfully
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('App will run without Firebase features');
    _firebaseInitialized = false;
  }
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const BlockerinoApp());
}

class BlockerinoApp extends StatelessWidget {
  const BlockerinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Firebase Analytics instance (only if initialized)
    final analytics = _firebaseInitialized ? FirebaseAnalytics.instance : null;
    final observer = analytics != null ? FirebaseAnalyticsObserver(analytics: analytics) : null;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, GameStateProvider>(
          create: (context) => GameStateProvider(
            settingsProvider: Provider.of<SettingsProvider>(context, listen: false),
          ),
          update: (context, settings, previous) => 
            previous ?? GameStateProvider(settingsProvider: settings),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Blockerino',
            debugShowCheckedModeBanner: false,
            navigatorObservers: observer != null ? [observer] : [],
            
            // Localization support
            locale: settings.currentLocale,
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
