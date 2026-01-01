import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';

/// Sound and haptic feedback service for game events
/// Uses actual audio files and haptic feedback for game sounds
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  static const int poolSize = 5;
  
  final Logger _logger = Logger();
  final Map<String, AudioPlayer> _audioPlayers = {};
  final AudioPlayer _bgmPlayer = AudioPlayer();
  
  // Sound pool for preventing audio overlap
  final List<AudioPlayer> _soundPool = [];
  int _currentPoolIndex = 0;

  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _initialized = false;

  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  /// Initialize audio players and preload sounds
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Set background music to loop
      _bgmPlayer.setReleaseMode(ReleaseMode.loop);

      // Create sound pool for overlapping sounds
      for (int i = 0; i < poolSize; i++) {
        final player = AudioPlayer();
        player.setReleaseMode(ReleaseMode.stop);
        _soundPool.add(player);
      }

      // Preload sound effects
      _audioPlayers['place'] = AudioPlayer();
      _audioPlayers['clear'] = AudioPlayer();
      _audioPlayers['combo'] = AudioPlayer();
      _audioPlayers['gameOver'] = AudioPlayer();
      _audioPlayers['error'] = AudioPlayer();
      _audioPlayers['refill'] = AudioPlayer();

      _initialized = true;
      _logger.i('SoundService initialized successfully with $poolSize pooled players');
    } catch (e) {
      _logger.e('Failed to initialize SoundService', error: e);
    }
  }

  /// Dispose all audio players
  void dispose() {
    _bgmPlayer.dispose();
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    for (var player in _soundPool) {
      player.dispose();
    }
    _audioPlayers.clear();
    _soundPool.clear();
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      stopBGM();
    }
  }

  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  /// Play sound using pooled players to prevent overlap
  Future<void> _playSound(String assetPath) async {
    if (!_soundEnabled || !_initialized || _soundPool.isEmpty) return;

    try {
      // Get next player from pool
      final player = _soundPool[_currentPoolIndex];
      _currentPoolIndex = (_currentPoolIndex + 1) % poolSize;

      // Stop current sound and play new one
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (e) {
      _logger.e('Failed to play sound from pool: $assetPath', error: e);
    }
  }

  /// Play background music
  /// DISABLED: BGM not needed yet
  Future<void> playBGM() async {
    // BGM disabled - return early
    return;
    // if (!_soundEnabled) return;
    // try {
    //   await _bgmPlayer.play(AssetSource('sounds/bgm_loop.mp3'));
    //   _logger.d('BGM playback started');
    // } catch (e) {
    //   _logger.e('Failed to play BGM', error: e);
    // }
  }

  /// Stop background music
  Future<void> stopBGM() async {
    await _bgmPlayer.stop();
  }

  /// Set background music volume (0.0 to 1.0)
  Future<void> setBGMVolume(double volume) async {
    await _bgmPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Play feedback when placing a piece
  Future<void> playPlace() async {
    if (_hapticsEnabled) {
      await HapticFeedback.lightImpact();
    }

    // Use pooled sound system for better performance
    await _playSound('sounds/pop.mp3');
  }

  /// Play feedback when clearing lines - more intense for more lines
  /// Note: Sound is skipped if hasCombo is true (combo sound will play instead)
  Future<void> playClear(int lineCount, {bool hasCombo = false}) async {
    if (_hapticsEnabled) {
      if (lineCount >= 3) {
        // Triple+ line clear - heavy impact
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 50));
        await HapticFeedback.heavyImpact();
      } else if (lineCount >= 2) {
        // Double line clear - medium impact
        await HapticFeedback.heavyImpact();
      } else {
        // Single line clear
        await HapticFeedback.mediumImpact();
      }
    }

    // CRITICAL FIX: Only play clear sound if there's NO combo
    // When there's a combo, playCombo() will be called instead
    // This prevents overlapping sounds (clear + combo playing at same time)
    if (!hasCombo) {
      debugPrint('🔊 Playing clear sound (no combo)');
      await _playSound('sounds/blast.mp3');
    } else {
      debugPrint('🔊 Skipping clear sound (combo will play instead)');
    }
  }

  /// Play feedback for combo - escalating pattern
  Future<void> playCombo(int comboLevel) async {
    debugPrint(
        '🔊 playCombo called: level=$comboLevel, soundEnabled=$_soundEnabled, initialized=$_initialized');

    if (_hapticsEnabled) {
      // Rapid clicks for combo feeling
      final clickCount = comboLevel.clamp(1, 5);
      for (int i = 0; i < clickCount; i++) {
        await HapticFeedback.selectionClick();
        if (i < clickCount - 1) {
          await Future.delayed(const Duration(milliseconds: 40));
        }
      }
    }

    if (_soundEnabled && _initialized) {
      debugPrint('🔊 Attempting to play combo sound...');
      await _playSound('sounds/combo.mp3');
      debugPrint('🔊 Combo sound played successfully!');
    } else {
      debugPrint(
          '🔊 Combo sound skipped: soundEnabled=$_soundEnabled, initialized=$_initialized');
    }
  }

  /// Play feedback when game is over
  Future<void> playGameOver() async {
    if (_hapticsEnabled) {
      // Dramatic ending pattern
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.heavyImpact();
    }

    await _playSound('sounds/game_over.mp3');
  }

  /// Play feedback when piece cannot be placed
  Future<void> playError() async {
    debugPrint('🔊 playError() called');
    debugPrint('   soundEnabled: $_soundEnabled');
    debugPrint('   initialized: $_initialized');
    debugPrint('   hapticsEnabled: $_hapticsEnabled');

    if (_hapticsEnabled) {
      try {
        await HapticFeedback.vibrate();
        debugPrint('   ✅ Haptic feedback triggered');
      } catch (e) {
        debugPrint('   ❌ Haptic feedback failed: $e');
      }
    } else {
      debugPrint('   ⏭️  Haptic feedback skipped (disabled)');
    }

    debugPrint('   🎵 Playing error sound...');
    await _playSound('sounds/error.mp3');
    debugPrint('   ✅ Error sound played');
  }

  /// Play feedback when hand is refilled
  Future<void> playRefill() async {
    if (_hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }

    // Use pop.mp3 for refill (no dedicated refill sound)
    await _playSound('sounds/pop.mp3');
  }
}
