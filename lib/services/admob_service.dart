import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Service to manage AdMob ads
///
/// Usage:
/// ```dart
/// final adService = AdMobService();
/// await adService.loadBannerAd();
/// await adService.showInterstitialAd();
/// ```
class AdMobService {
  // Use test ads in debug mode, production ads in release mode
  // NOTE: If you get 403 errors, temporarily use test ads to verify setup
  // Configuration is now in AppConfig.forceTestAds

  static String get _bannerAdUnitId => (AppConfig.forceTestAds || kDebugMode)
      ? AppConfig.testBannerAdUnitId
      : AppConfig.productionBannerAdUnitId;
  static String get _interstitialAdUnitId =>
      (AppConfig.forceTestAds || kDebugMode)
          ? AppConfig.testInterstitialAdUnitId
          : AppConfig.productionInterstitialAdUnitId;
  static String get _rewardedAdUnitId => (AppConfig.forceTestAds || kDebugMode)
      ? AppConfig.testRewardedAdUnitId
      : AppConfig.productionRewardedAdUnitId;

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  /// Load a banner ad
  /// Returns true if ad request was initiated (not if it loaded successfully)
  Future<bool> loadBannerAd({
    AdSize? adSize,
    void Function(BannerAd)? onAdLoaded,
    void Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    try {
      _bannerAd?.dispose();

      debugPrint('📱 AdMobService: Loading banner ad');
      debugPrint('   Ad Unit ID: $_bannerAdUnitId');
      debugPrint('   Ad size: ${adSize ?? AdSize.banner}');
      debugPrint('   Debug mode: $kDebugMode');
      debugPrint('   Force test ads: ${AppConfig.forceTestAds}');
      debugPrint(
          '   Using: ${(AppConfig.forceTestAds || kDebugMode) ? "TEST ADS" : "PRODUCTION ADS"}');

      _bannerAd = BannerAd(
        adUnitId:
            _bannerAdUnitId, // This is now a getter, so it will use the correct ID
        size: adSize ?? AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('✅ AdMobService: Banner ad loaded successfully!');
            onAdLoaded?.call(ad as BannerAd);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('❌ AdMobService: Banner ad failed to load');
            debugPrint('   Error code: ${error.code}');
            debugPrint('   Error message: ${error.message}');
            debugPrint('   Error domain: ${error.domain}');
            debugPrint('   Response info: ${error.responseInfo}');

            // Common error codes:
            // 0 = ERROR_CODE_INTERNAL_ERROR
            // 1 = ERROR_CODE_INVALID_REQUEST
            // 2 = ERROR_CODE_NETWORK_ERROR
            // 3 = ERROR_CODE_NO_FILL (403 usually means this)
            // 8 = ERROR_CODE_INVALID_AD_SIZE

            if (error.code == 3) {
              debugPrint('⚠️ ERROR CODE 3 (403): This usually means:');
              debugPrint('   1. Ad Unit ID is incorrect or not activated');
              debugPrint('   2. App is not properly linked to AdMob account');
              debugPrint('   3. Ad Unit is not active yet in AdMob Console');
              debugPrint('   💡 Solution: Check AdMob Console and verify:');
              debugPrint('      - App ID matches: ${AppConfig.admobAppId}');
              debugPrint(
                  '      - Ad Unit ID is correct: ${AppConfig.productionBannerAdUnitId}');
              debugPrint('      - Ad Unit status is "Active" in AdMob Console');
            }

            ad.dispose();
            _bannerAd = null;
            onAdFailedToLoad?.call(error);
          },
          onAdOpened: (ad) => debugPrint('📱 AdMobService: Banner ad opened'),
          onAdClosed: (ad) {
            debugPrint('📱 AdMobService: Banner ad closed');
            ad.dispose();
            _bannerAd = null;
          },
        ),
      );

      _bannerAd!.load();
      debugPrint('📱 AdMobService: Banner ad load() called');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ AdMobService: Error loading banner ad: $e');
      debugPrint('   Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get the loaded banner ad widget
  Widget? getBannerAdWidget() {
    if (_bannerAd == null) return null;

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  /// Load an interstitial ad
  Future<bool> loadInterstitialAd({
    void Function()? onAdDismissed,
    void Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial ad loaded');
            _interstitialAd = ad;

            _interstitialAd!.fullScreenContentCallback =
                FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Interstitial ad dismissed');
                ad.dispose();
                _interstitialAd = null;
                onAdDismissed?.call();
                // Preload next interstitial ad
                loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Interstitial ad failed to show: $error');
                ad.dispose();
                _interstitialAd = null;
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: $error');
            _interstitialAd = null;
            onAdFailedToLoad?.call(error);
          },
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
      return false;
    }
  }

  /// Show interstitial ad (if loaded)
  /// Returns true if ad was shown, false if not loaded
  Future<bool> showInterstitialAd() async {
    if (_interstitialAd == null) {
      debugPrint('Interstitial ad not loaded, loading now...');
      await loadInterstitialAd();
      return false;
    }

    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      return false;
    }
  }

  /// Load a rewarded ad
  Future<bool> loadRewardedAd({
    required void Function(RewardedAd, RewardItem) onRewarded,
    void Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Rewarded ad loaded');
            _rewardedAd = ad;

            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Rewarded ad dismissed');
                ad.dispose();
                _rewardedAd = null;
                // Preload next rewarded ad
                loadRewardedAd(onRewarded: onRewarded);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Rewarded ad failed to show: $error');
                ad.dispose();
                _rewardedAd = null;
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load: $error');
            _rewardedAd = null;
            onAdFailedToLoad?.call(error);
          },
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Error loading rewarded ad: $e');
      return false;
    }
  }

  /// Show rewarded ad (if loaded)
  /// Returns true if ad was shown, false if not loaded
  Future<bool> showRewardedAd({
    required void Function(RewardedAd, RewardItem) onRewarded,
  }) async {
    if (_rewardedAd == null) {
      debugPrint('Rewarded ad not loaded, loading now...');
      await loadRewardedAd(onRewarded: onRewarded);
      return false;
    }

    try {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          onRewarded(_rewardedAd!, reward);
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      return false;
    }
  }

  /// Dispose all ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
  }
}
