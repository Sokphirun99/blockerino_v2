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
  Future<void> playClear(int lineCount) async {
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
    
    if (_soundEnabled && _initialized) {
      try {
        await _audioPlayers['clear']?.play(AssetSource('sounds/blast.wav'));
      } catch (e) {
        _logger.e('Failed to play clear sound', error: e);
      }
    }
  }

  /// Play feedback for combo - escalating pattern
  Future<void> playCombo(int comboLevel) async {
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
      try {
        await _audioPlayers['combo']?.play(AssetSource('sounds/combo.mp3'));
      } catch (e) {
        _logger.e('Failed to play combo sound', error: e);
      }
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
    if (_hapticsEnabled) {
      await HapticFeedback.vibrate();
    }
    
    if (_soundEnabled && _initialized) {
      try {
        await _audioPlayers['error']?.play(AssetSource('sounds/error.mp3'));
      } catch (e) {
        _logger.e('Failed to play error sound', error: e);
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
