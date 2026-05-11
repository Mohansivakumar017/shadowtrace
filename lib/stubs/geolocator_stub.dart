// Web stub for geolocator
class Position {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? heading;
  final double? speed;

  Position({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.heading,
    this.speed,
  });
}

class Geolocator {
  static Future<bool> requestPermission() async => true;

  static Future<bool> isLocationServiceEnabled() async => false;

  static Stream<Position> getPositionStream({required LocationSettings? locationSettings}) {
    throw UnsupportedError('Geolocator not available on web');
  }

  static Future<Position?> getCurrentPosition() async => null;

  static Future<LocationPermission> checkPermission() async {
    return LocationPermission.denied;
  }
}

class LocationSettings {
  final LocationAccuracy accuracy;
  final int distanceFilter;
  final Duration? timeLimit;

  LocationSettings({
    required this.accuracy,
    required this.distanceFilter,
    this.timeLimit,
  });
}

enum LocationAccuracy { best, bestForNavigation, high, medium, low, lowestAccuracy }

enum LocationPermission { denied, deniedForever, unableToDetermine, whileInUse, always }
