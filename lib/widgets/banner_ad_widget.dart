import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';

/// Widget that displays a banner ad at the bottom of the screen
class BannerAdWidget extends StatefulWidget {
  final AdMobService adService;
  final AdSize? adSize;

  const BannerAdWidget({
    super.key,
    required this.adService,
    this.adSize,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  bool _adLoaded = false;
  bool _isLoading = true;
  String? _errorMessage;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  // Timer references for proper cleanup
  Timer? _initTimer;
  Timer? _retryTimer;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('🎯 BannerAdWidget: initState() called');
    debugPrint('🎯 BannerAdWidget: Widget is being created');
    // Wait a bit for AdMob to be fully initialized
    _initTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        debugPrint('🎯 BannerAdWidget: Starting to load ad after delay');
        _loadAd();
      } else {
        debugPrint('⚠️ BannerAdWidget: Widget not mounted, skipping ad load');
      }
    });
  }

  @override
  void dispose() {
    // ✅ Cancel all timers to prevent memory leaks and infinite loops
    _initTimer?.cancel();
    _retryTimer?.cancel();
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAd() async {
    // ✅ Cancel any existing retry timer before starting a new load
    _retryTimer?.cancel();
    _loadingTimer?.cancel();

    debugPrint('🎯 BannerAdWidget: Loading ad... (attempt ${_retryCount + 1})');
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous error when retrying
    });

    // Load ad (this is async but doesn't wait for the ad to actually load)
    await widget.adService.loadBannerAd(
      adSize: widget.adSize ?? AdSize.banner,
      onAdLoaded: (_) {
        debugPrint('✅ BannerAdWidget: Ad loaded successfully!');
        if (mounted) {
          setState(() {
            _adLoaded = true;
            _isLoading = false;
          });
        }
      },
      onAdFailedToLoad: (error) {
        debugPrint('❌ BannerAdWidget: Ad failed to load: $error');
        debugPrint('   Error code: ${error.code}');
        debugPrint('   Error message: ${error.message}');
        debugPrint('   Error domain: ${error.domain}');
        debugPrint('   Retry count: $_retryCount');

        // Retry on network errors (code 2) or no fill errors (code 3)
        if (mounted &&
            _retryCount < _maxRetries &&
            (error.code == 2 || error.code == 3)) {
          _retryCount++;
          debugPrint(
              '🔄 BannerAdWidget: Retrying ad load (attempt $_retryCount/$_maxRetries)...');
          // Wait a bit before retrying (exponential backoff)
          // ✅ Use Timer instead of Future.delayed so it can be cancelled
          _retryTimer = Timer(Duration(seconds: _retryCount * 2), () {
            if (mounted) {
              _loadAd();
            }
          });
          return; // Don't set error message yet, we're retrying
        }

        if (mounted) {
          setState(() {
            _adLoaded = false;
            _isLoading = false;
            // Show user-friendly error message
            if (error.code == 2) {
              _errorMessage = 'Network error. Check your connection.';
            } else if (error.code == 3) {
              _errorMessage = 'Ad not available. Please try again later.';
            } else {
              _errorMessage = 'Failed to load ad: ${error.message}';
            }
          });
        }
      },
    );

    // Set loading to false after a short delay if ad hasn't loaded yet
    // (The actual loading happens asynchronously via callbacks)
    // ✅ Use Timer instead of Future.delayed so it can be cancelled
    _loadingTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && !_adLoaded && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Get responsive ad size - use the actual ad size height
    // This ensures the banner adapts to different screen sizes
    final adSize = widget.adSize ?? AdSize.banner;
    final adHeight = adSize.height.toDouble();

    // For very small screens, ensure minimum height
    const minHeight = 50.0;
    final finalHeight = adHeight < minHeight ? minHeight : adHeight;

    // ALWAYS show something - never return empty widget
    // Show loading indicator while ad is loading
    if (_isLoading) {
      return Container(
        height: finalHeight,
        width: double.infinity,
        color: Colors.purple.withOpacity(0.3), // Make it very visible
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9d4edd)),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Loading Ad...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error message - ALWAYS show something
    if (_errorMessage != null) {
      return Container(
        height: finalHeight,
        width: double.infinity,
        color: Colors.red.withOpacity(0.4), // Make it very visible
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (_retryCount < _maxRetries)
                const Text(
                  'Retrying...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Show ad if loaded
    if (!_adLoaded) {
      return Container(
        height: finalHeight,
        width: double.infinity,
        color: Colors.blue.withOpacity(0.4), // Make it very visible
        child: const Center(
          child: Text(
            'Ad Not Loaded Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final adWidget = widget.adService.getBannerAdWidget();
    if (adWidget == null) {
      return Container(
        height: finalHeight,
        width: double.infinity,
        color: Colors.yellow.withOpacity(0.4), // Make it very visible
        child: const Center(
          child: Text(
            'Ad Widget is Null',
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      height: finalHeight,
      width: double.infinity,
      color: Colors.green.withOpacity(0.2), // Temporary: make it visible
      alignment: Alignment.center,
      child: adWidget,
    );
  }
}
