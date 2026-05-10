class AppConfig {
  static const String apiBaseUrl = 'https://YOUR_API_ENDPOINT/dev';
  static const String cognitoUserPoolId = 'ap-south-1_XXXXXXX';
  static const String cognitoClientId = 'YOUR_CLIENT_ID';
  static const String cognitoIdentityPoolId = 'ap-south-1:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX';
  static const String alsTrackerName = 'shadowtrace-tracker';
  static const String alsRouteCalcName = 'shadowtrace-route-calc';
  static const String alsMapStyle = 'https://maps.geo.ap-south-1.amazonaws.com/maps/v0/maps/standard/style';

  static const int deadZoneThresholdSeconds = 300;
  static const int stallRadiusMeters = 25;
  static const int locationPollIntervalSeconds = 10;
}
