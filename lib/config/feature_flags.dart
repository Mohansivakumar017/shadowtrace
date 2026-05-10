class FeatureFlags {
  // Requires SNS push notifications configured
  static const bool SILENT_SOS_ENABLED = false;

  // Requires Location Service GetStaticMap and local SQLite caching
  static const bool OFFLINE_MAP_CACHE = false;

  // Requires device vibration capability and hardware_buttons package
  static const bool PRE_ALERT_VIBRATION = true;

  // Requires Location Service SearchPlaceIndexForPosition
  static const bool SAFETY_SCORES_ENABLED = true;
}
