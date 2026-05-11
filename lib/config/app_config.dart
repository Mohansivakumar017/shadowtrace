class AppConfig {
  // API 1 — Location & Weather
  static const String locationApiBase =
      'https://bt0afo9upa.execute-api.us-east-1.amazonaws.com/dev';

  // API 2 — Alert System
  static const String alertApiBase =
      'https://ycr7hmmo89.execute-api.us-east-1.amazonaws.com/dev';

  // Individual endpoints
  static const String locationEndpoint = '$locationApiBase/location';
  static const String weatherDataEndpoint =
      '$locationApiBase/wheatherdataget';
  static const String weatherForecastEndpoint =
      '$locationApiBase/wheatherforecasting';
  static const String triggerAlertEndpoint = '$alertApiBase/trigger-alert';
  static const String respondAlertEndpoint = '$alertApiBase/respond-alert';
  static const String audioStreamEndpoint = '$alertApiBase/audio-stream';
  static const String heartbeatEndpoint = '$alertApiBase/heartbeat';
  static const String safetyScoreEndpoint = '$alertApiBase/safety-score';
  static const String contactsEndpoint = '$alertApiBase/contacts';

  // Additional endpoints (same base as location API)
  static const String routeEndpoint = '$locationApiBase/route';
  static const String tripEndpoint = '$locationApiBase/trip';
  static const String devicePositionEndpoint = '$locationApiBase/device-position';

  // AWS config
  static const String awsRegion = 'us-east-1';
  static const String alsTrackerName = 'shadowtrace-tracker';
  static const String alsRouteCalcName = 'shadowtrace-route-calc';
  static const String alsGeofenceCollection = 'shadowtrace-routes';
  static const String alsPlaceIndex = 'shadowtrace-place-index';

  // Dead-zone timer configuration
  static const int deadZoneThresholdSeconds = 300;
  static const int preAlertWarnningSeconds = 60;
  static const int stallRadiusMeters = 25;
  static const int locationPollIntervalSeconds = 10;

  // Audio streaming
  static const int audioChunkUploadIntervalSeconds = 30;

  // Cognito config
  static const String userPoolId = 'us-east-1_QUhSwcEDN';
  static const String clientId = '7kt3lo1bge59tslkq4r67u05o5';
  static const String identityPoolId =
      'us-east-1:4fb622ac-d282-40f5-a232-3e852637a305';
}
