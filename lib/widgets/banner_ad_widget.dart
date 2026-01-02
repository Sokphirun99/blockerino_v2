import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';

/// Debug print helper - only prints in debug mode
void _log(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

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
    _log('🎯 BannerAdWidget: initState() called');
    _log('🎯 BannerAdWidget: Widget is being created');
    // Wait a bit for AdMob to be fully initialized
    _initTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _log('🎯 BannerAdWidget: Starting to load ad after delay');
        _loadAd();
      } else {
        _log('⚠️ BannerAdWidget: Widget not mounted, skipping ad load');
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

    _log('🎯 BannerAdWidget: Loading ad... (attempt ${_retryCount + 1})');
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous error when retrying
    });

    // Load ad (this is async but doesn't wait for the ad to actually load)
    await widget.adService.loadBannerAd(
      adSize: widget.adSize ?? AdSize.banner,
      onAdLoaded: (_) {
        _log('✅ BannerAdWidget: Ad loaded successfully!');
        if (mounted) {
          setState(() {
            _adLoaded = true;
            _isLoading = false;
          });
        }
      },
      onAdFailedToLoad: (error) {
        _log('❌ BannerAdWidget: Ad failed to load: $error');
        _log('   Error code: ${error.code}');
        _log('   Error message: ${error.message}');
        _log('   Error domain: ${error.domain}');
        _log('   Retry count: $_retryCount');

        // Retry on network errors (code 2) or no fill errors (code 3)
        if (mounted &&
            _retryCount < _maxRetries &&
            (error.code == 2 || error.code == 3)) {
          _retryCount++;
          _log('🔄 BannerAdWidget: Retrying ad load (attempt $_retryCount/$_maxRetries)...');
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

    // Show minimal placeholder while ad is loading (no debug UI in production)
    if (_isLoading) {
      return SizedBox(
        height: finalHeight,
        width: double.infinity,
      );
    }

    // Show nothing if error (ad space collapses gracefully)
    if (_errorMessage != null) {
      // In debug mode, show error for debugging
      if (kDebugMode) {
        return Container(
          height: finalHeight,
          width: double.infinity,
          color: Colors.red.withValues(alpha: 0.2),
          child: Center(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      // In production, just show empty space
      return SizedBox(height: finalHeight, width: double.infinity);
    }

    // Show empty space if ad not loaded yet
    if (!_adLoaded) {
      return SizedBox(height: finalHeight, width: double.infinity);
    }

    final adWidget = widget.adService.getBannerAdWidget();
    if (adWidget == null) {
      return SizedBox(height: finalHeight, width: double.infinity);
    }

    return SizedBox(
      height: finalHeight,
      width: double.infinity,
      child: adWidget,
    );
  }
}
