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

  final Logger _logger = Logger();
  final Map<String, AudioPlayer> _audioPlayers = {};
  final AudioPlayer _bgmPlayer = AudioPlayer();

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

      // Preload sound effects
      _audioPlayers['place'] = AudioPlayer();
      _audioPlayers['clear'] = AudioPlayer();
      _audioPlayers['combo'] = AudioPlayer();
      _audioPlayers['gameOver'] = AudioPlayer();
      _audioPlayers['error'] = AudioPlayer();
      _audioPlayers['refill'] = AudioPlayer();

      _initialized = true;
      _logger.i('SoundService initialized successfully');
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
    _audioPlayers.clear();
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

    if (_soundEnabled && _initialized) {
      try {
        await _audioPlayers['place']?.play(AssetSource('sounds/pop.mp3'));
      } catch (e) {
        _logger.e('Failed to play place sound', error: e);
      }
    }
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
    if (_soundEnabled && _initialized && !hasCombo) {
      debugPrint('🔊 Playing clear sound (no combo)');
      try {
        await _audioPlayers['clear']?.play(AssetSource('sounds/blast.mp3'));
      } catch (e) {
        _logger.e('Failed to play clear sound', error: e);
      }
    } else if (hasCombo) {
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
      try {
        final player = _audioPlayers['combo'];
        if (player != null) {
          // Stop any currently playing combo sound first to prevent conflicts
          await player.stop();
          await player.play(AssetSource('sounds/combo.mp3'));
          debugPrint('🔊 Combo sound played successfully!');
        } else {
          debugPrint('🔊 WARNING: Combo audio player not initialized');
          _logger.w('Combo audio player not initialized');
        }
      } catch (e) {
        debugPrint('🔊 ERROR: Failed to play combo sound: $e');
        _logger.e('Failed to play combo sound: $e');
        // Fallback: try to reinitialize the player
        try {
          debugPrint('🔊 Attempting to reinitialize combo player...');
          _audioPlayers['combo'] = AudioPlayer();
          await _audioPlayers['combo']?.stop(); // Stop before playing
          await _audioPlayers['combo']?.play(AssetSource('sounds/combo.mp3'));
          debugPrint(
              '🔊 Combo sound played successfully after reinitialization!');
        } catch (e2) {
          debugPrint('🔊 ERROR: Failed to reinitialize combo player: $e2');
          _logger.e('Failed to reinitialize combo player: $e2');
        }
      }
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

    if (_soundEnabled && _initialized) {
      try {
        await _audioPlayers['gameOver']
            ?.play(AssetSource('sounds/game_over.mp3'));
      } catch (e) {
        _logger.e('Failed to play game over sound', error: e);
      }
    }
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

    if (_soundEnabled && _initialized) {
      debugPrint('   🎵 Attempting to play error sound...');
      try {
        final player = _audioPlayers['error'];
        if (player != null) {
          debugPrint('   ✅ Error audio player found');
          // Stop any currently playing error sound first to prevent conflicts
          await player.stop();
          await player.play(AssetSource('sounds/error.mp3'));
          debugPrint('   ✅ Error sound play() called successfully');
        } else {
          debugPrint('   ❌ ERROR: Error audio player is null!');
          _logger.e('Error audio player not initialized');
          // Fallback: try to reinitialize the player
          try {
            debugPrint('   🔄 Attempting to reinitialize error player...');
            _audioPlayers['error'] = AudioPlayer();
            await _audioPlayers['error']?.stop(); // Stop before playing
            await _audioPlayers['error']?.play(AssetSource('sounds/error.mp3'));
            debugPrint(
                '   ✅ Error sound played successfully after reinitialization!');
          } catch (e2) {
            debugPrint('   ❌ ERROR: Failed to reinitialize error player: $e2');
            _logger.e('Failed to reinitialize error player: $e2');
          }
        }
      } catch (e, stackTrace) {
        debugPrint('   ❌ ERROR: Failed to play error sound');
        debugPrint('   Error: $e');
        debugPrint('   Stack trace: $stackTrace');
        _logger.e('Failed to play error sound',
            error: e, stackTrace: stackTrace);
        // Fallback: try to reinitialize the player
        try {
          debugPrint(
              '   🔄 Attempting to reinitialize error player after error...');
          _audioPlayers['error'] = AudioPlayer();
          await _audioPlayers['error']?.stop(); // Stop before playing
          await _audioPlayers['error']?.play(AssetSource('sounds/error.mp3'));
          debugPrint(
              '   ✅ Error sound played successfully after reinitialization!');
        } catch (e2) {
          debugPrint('   ❌ ERROR: Failed to reinitialize error player: $e2');
          _logger.e('Failed to reinitialize error player: $e2');
        }
      }
    } else {
      if (!_soundEnabled) {
        debugPrint('   ⏭️  Sound skipped: sound is disabled');
      }
      if (!_initialized) {
        debugPrint('   ⏭️  Sound skipped: SoundService not initialized');
      }
    }
  }

  /// Play feedback when hand is refilled
  Future<void> playRefill() async {
    if (_hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }

    if (_soundEnabled && _initialized) {
      try {
        // Use pop.mp3 for refill (no dedicated refill sound)
        await _audioPlayers['refill']?.play(AssetSource('sounds/pop.mp3'));
      } catch (e) {
        _logger.e('Failed to play refill sound', error: e);
      }
    }
  }
}
