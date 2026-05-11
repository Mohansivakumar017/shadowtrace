import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API Endpoints from environment
  static String get apiBaseUrl =>
      dotenv.env['AWS_API_GATEWAY_URL'] ??
      dotenv.env['API_BASE_URL'] ??
      'https://api.shadowtrace.local/dev';

  static String get locationApiBase => apiBaseUrl;
  static String get alertApiBase => apiBaseUrl;

  // Individual endpoints
  static String get locationEndpoint => '$apiBaseUrl/location';
  static String get weatherDataEndpoint => '$apiBaseUrl/weather';
  static String get weatherForecastEndpoint => '$apiBaseUrl/forecast';
  static String get triggerAlertEndpoint => '$apiBaseUrl/sos';
  static String get respondAlertEndpoint => '$apiBaseUrl/respond-alert';
  static String get audioStreamEndpoint => '$apiBaseUrl/audio-stream';
  static String get heartbeatEndpoint => '$apiBaseUrl/heartbeat';
  static String get safetyScoreEndpoint => '$apiBaseUrl/safety-score';
  static String get contactsEndpoint => '$apiBaseUrl/contacts';
  static String get routeEndpoint => '$apiBaseUrl/route_calc';
  static String get tripEndpoint => '$apiBaseUrl/trip';
  static String get devicePositionEndpoint => '$apiBaseUrl/device-position';

  // AWS Configuration
  static String get awsRegion => dotenv.env['AWS_REGION'] ?? 'us-east-1';
  static String get alsTrackerName =>
      dotenv.env['ALS_TRACKER_NAME'] ?? 'shadowtrace-tracker';
  static String get alsRouteCalcName =>
      dotenv.env['ALS_ROUTE_CALC_NAME'] ?? 'shadowtrace-route-calc';
  static String get alsGeofenceCollection =>
      dotenv.env['ALS_GEOFENCE_COLLECTION'] ?? 'shadowtrace-routes';
  static String get alsPlaceIndex =>
      dotenv.env['ALS_PLACE_INDEX'] ?? 'shadowtrace-place-index';

  // Configuration from environment with defaults
  static int get deadZoneThresholdSeconds =>
      int.tryParse(dotenv.env['DEAD_ZONE_THRESHOLD_SECONDS'] ?? '300') ?? 300;
  static int get preAlertWarnningSeconds => 60;
  static int get stallRadiusMeters => 25;
  static int get locationPollIntervalSeconds =>
      int.tryParse(dotenv.env['LOCATION_POLL_INTERVAL_SECONDS'] ?? '10') ?? 10;
  static int get audioChunkUploadIntervalSeconds => 30;

  // Cognito Configuration
  static String get userPoolId =>
      dotenv.env['COGNITO_USER_POOL_ID'] ?? 'us-east-1_XXXXXXXXX';
  static String get clientId =>
      dotenv.env['COGNITO_CLIENT_ID'] ?? 'xxxxxxxxxxxxxxxxxxxxxxxxxx';
  static String get identityPoolId =>
      dotenv.env['COGNITO_IDENTITY_POOL_ID'] ?? 'us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

  // External API Keys
  static String get owmApiKey => dotenv.env['OWM_KEY'] ?? '';
  static String get hereApiKey => dotenv.env['HERE_API_KEY'] ?? '';
}
