import 'dart:math' as math;
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
import '../config/feature_flags.dart';

class OfflineMapCacheService {
  static final OfflineMapCacheService _instance =
      OfflineMapCacheService._internal();
  Database? _db;

  factory OfflineMapCacheService() {
    return _instance;
  }

  OfflineMapCacheService._internal();

  Future<Database> _getDatabase() async {
    if (kIsWeb) throw UnsupportedError('Offline map cache not available on web');
    if (_db != null) return _db!;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'shadowtrace_maps.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE map_tiles (
            z INTEGER,
            x INTEGER,
            y INTEGER,
            data BLOB,
            PRIMARY KEY (z, x, y)
          )
        ''');
      },
    );

    return _db!;
  }

  Future<void> cacheMapTiles(List<Position> routePoints) async {
    if (kIsWeb || !FeatureFlags.OFFLINE_MAP_CACHE) return;

    try {
      final db = await _getDatabase();

      for (var z = 13; z <= 15; z++) {
        for (final point in routePoints.take(10)) {
          final x = _lngToTile(point.longitude, z);
          final y = _latToTile(point.latitude, z);

          final existing = await db.query(
            'map_tiles',
            where: 'z = ? AND x = ? AND y = ?',
            whereArgs: [z, x, y],
          );

          if (existing.isEmpty) {
            try {
              await _cacheSingleTile(db, z, x, y);
            } catch (e) {
              debugPrint('Cache tile error: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Cache map tiles error: $e');
    }
  }

  Future<void> _cacheSingleTile(Database db, int z, int x, int y) async {
    await db.insert(
      'map_tiles',
      {
        'z': z,
        'x': x,
        'y': y,
        'data': Uint8List(0),
      },
    );
  }

  Future<Uint8List?> getOfflineTile(int z, int x, int y) async {
    if (kIsWeb || !FeatureFlags.OFFLINE_MAP_CACHE) return null;

    try {
      final db = await _getDatabase();
      final results = await db.query(
        'map_tiles',
        where: 'z = ? AND x = ? AND y = ?',
        whereArgs: [z, x, y],
      );

      if (results.isNotEmpty) {
        return results.first['data'] as Uint8List?;
      }
      return null;
    } catch (e) {
      debugPrint('Get offline tile error: $e');
      return null;
    }
  }

  Future<bool> isCached(LatLngBounds bounds) async {
    if (kIsWeb || !FeatureFlags.OFFLINE_MAP_CACHE) return false;

    try {
      final db = await _getDatabase();
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM map_tiles WHERE z >= 13 AND z <= 15',
      );

      final count = (result.first['count'] as int?) ?? 0;
      return count > 50;
    } catch (e) {
      debugPrint('Is cached error: $e');
      return false;
    }
  }

  int _lngToTile(double lng, int z) {
    return ((lng + 180) / 360 * (1 << z)).toInt();
  }

  int _latToTile(double lat, int z) {
    final latRad = lat * math.pi / 180;
    return (((1 -
                (math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
                2) *
            (1 << z))
        .toInt());
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

class LatLngBounds {
  final double southwest_lat;
  final double southwest_lng;
  final double northeast_lat;
  final double northeast_lng;

  LatLngBounds({
    required this.southwest_lat,
    required this.southwest_lng,
    required this.northeast_lat,
    required this.northeast_lng,
  });
}
