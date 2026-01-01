import 'package:flutter/material.dart';

/// A reusable loading screen widget that displays the KR Studio logo
/// with progress bar and percentage - user-friendly for long loading times
class LoadingScreenWidget extends StatefulWidget {
  final String? message;
  final double logoSize;
  final Stream<double>? progressStream; // 0.0 to 1.0
  final double? staticProgress; // For static progress display

  const LoadingScreenWidget({
    super.key,
    this.message = 'Loading...',
    this.logoSize = 150,
    this.progressStream,
    this.staticProgress,
  });

  @override
  State<LoadingScreenWidget> createState() => _LoadingScreenWidgetState();
}

class _LoadingScreenWidgetState extends State<LoadingScreenWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Listen to progress stream if provided
    widget.progressStream?.listen((progress) {
      if (mounted) {
        setState(() {
          _progress = progress.clamp(0.0, 1.0);
        });
      }
    });

    // Use static progress if provided
    if (widget.staticProgress != null) {
      _progress = widget.staticProgress!.clamp(0.0, 1.0);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF0f0f1e),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenWidth * 0.7,
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: Image.asset(
                  'assets/loading/loading_screen-removebg-preview.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.games,
                      color: const Color(0xFF9d4edd),
                      size: widget.logoSize,
                    );
                  },
                ),
              ),

              const Spacer(),

              // Loading message
              if (widget.message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    widget.message!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Progress bar
              Column(
                children: [
                  // Percentage
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFF9d4edd),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  SizedBox(
                    height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Stack(
                        children: [
                          // Background
                          Container(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),

                          // Progress
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progress,
                            child: AnimatedBuilder(
                              animation: _shimmerController,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: const [
                                        Color(0xFF9d4edd),
                                        Color(0xFFc77dff),
                                        Color(0xFF9d4edd),
                                      ],
                                      stops: [
                                        (_shimmerController.value - 0.3)
                                            .clamp(0.0, 1.0),
                                        _shimmerController.value,
                                        (_shimmerController.value + 0.3)
                                            .clamp(0.0, 1.0),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
