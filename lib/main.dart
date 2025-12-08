import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'screens/main_menu_screen.dart';
import 'providers/game_state_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Firebase Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const BlockerinoApp());
}

class BlockerinoApp extends StatelessWidget {
  const BlockerinoApp({super.key});

  // Firebase Analytics instance
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
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
      child: MaterialApp(
        title: 'Blockerino',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [observer],
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
  }
}
