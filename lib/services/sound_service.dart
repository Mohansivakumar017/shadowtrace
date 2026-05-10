import 'dart:developer' as dev;

/// Wrapper for your existing sound/alarm logic.
/// Plug in your existing sound function here.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _isAlarmPlaying = false;

  void playEmergencySiren() {
    if (_isAlarmPlaying) return;
    dev.log("📢 Triggering existing Emergency Siren...");

    // TODO: CALL YOUR EXISTING SOUND METHOD HERE
    // Example: ExistingSoundPlugin.play('assets/sounds/siren.mp3');

    _isAlarmPlaying = true;
  }

  void stopSiren() {
    dev.log("🔇 Silencing Siren...");

    // TODO: CALL YOUR EXISTING STOP METHOD HERE
    // Example: ExistingSoundPlugin.stop();

    _isAlarmPlaying = false;
  }
}
