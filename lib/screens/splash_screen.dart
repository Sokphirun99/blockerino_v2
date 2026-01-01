import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../services/mission_service.dart';
import '../services/streak_service.dart';
import 'main_menu_screen.dart';

/// Professional splash screen with animated logo and app initialization
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade animation (first 50% of duration)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    // Scale animation (elastic bounce effect)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    // Start animation and initialize app
    _controller.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Initialize app services and navigate to main menu
  Future<void> _initializeApp() async {
    try {
      // Ensure minimum splash duration for branding
      final initFuture = _performInitialization();
      final minDurationFuture = Future.delayed(const Duration(seconds: 2));

      // Wait for both initialization and minimum duration
      await Future.wait([initFuture, minDurationFuture]);

      // Navigate to main menu
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainMenuScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error during app initialization: $e');
      
      // Still navigate on error after minimum duration
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainMenuScreen(),
          ),
        );
      }
    }
  }

  /// Perform actual service initialization
  Future<void> _performInitialization() async {
    debugPrint('🚀 Initializing app services...');

    // Initialize core services
    await Future.wait([
      SoundService().initialize(),
      // Mission and streak services are lightweight, no async init needed
    ]);

    // Initialize mission and streak services
    final missionService = MissionService();
    final streakService = StreakService();
    
    // Pre-load data (but don't wait for it)
    missionService.getDailyMissions();
    streakService.getStreak();

    debugPrint('✅ App services initialized successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Game icon/logo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ECDC4),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.grid_view_rounded,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Game title
                        const Text(
                          'BLOCKERINO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Subtitle
                        Text(
                          'Puzzle Game',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Loading indicator
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: Color(0xFF4ECDC4),
                            strokeWidth: 3,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Loading text
                        Text(
                          'Loading...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}