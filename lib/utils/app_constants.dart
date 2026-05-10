class AppConstants {
  static const String appName = 'ShadowTrace';

  // API Endpoints (AWS API Gateway)
  static const String baseUrl = 'https://api.shadowtrace.com/v1';
  static const String triggerAlert = '/trigger-alert';
  static const String respondAlert = '/respond-alert';
  static const String alertStatus = '/alert-status';

  // Storage Keys
  static const String tokenKey = 'fcm_token';
  static const String userKey = 'user_data';

  // Animation Assets
  static const String splashAnimation = 'assets/animations/splash.json';
  static const String emergencyAnimation = 'assets/animations/emergency.json';
}
