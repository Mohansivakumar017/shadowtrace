class FeatureFlags {
  // Silent SOS — power button ×5 sequence
  static const bool SILENT_SOS_ENABLED = true;

  // Offline map caching for dead zones
  static const bool OFFLINE_MAP_CACHE = true;

  // Pre-alert vibration warning at 60s before dead-zone alert
  static const bool PRE_ALERT_VIBRATION = true;

  // Aggregated route safety scores
  static const bool SAFETY_SCORES_ENABLED = true;

  // Remote audio monitoring during SOS
  static const bool AUDIO_MONITORING = true;
}
