import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/main_menu_screen.dart';
import 'providers/game_state_provider.dart';
import 'providers/settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
