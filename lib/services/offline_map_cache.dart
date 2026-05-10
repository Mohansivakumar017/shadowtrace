import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';
import '../config/app_config.dart';
import '../config/feature_flags.dart';

class OfflineMapCacheService {
  static final OfflineMapCacheService _instance = OfflineMapCacheService._internal();
  Database? _db;

  factory OfflineMapCacheService() {
    return _instance;
  }

  OfflineMapCacheService._internal();

  Future<Database> _getDatabase() async {
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

  Future<void> cacheMapTiles(List<List<double>> boundsPolygon) async {
    if (!FeatureFlags.OFFLINE_MAP_CACHE) return;

    try {
      final db = await _getDatabase();
      final session = await Amplify.Auth.getSession();

      if (!session.isSignedIn) return;

      final credentials = session.credentials;
      if (credentials == null) return;

      for (var z = 13; z <= 15; z++) {
        for (final point in boundsPolygon.take(10)) {
          final x = _lngToTile(point[0], z);
          final y = _latToTile(point[1], z);

          final existing = await db.query(
            'map_tiles',
            where: 'z = ? AND x = ? AND y = ?',
            whereArgs: [z, x, y],
          );

          if (existing.isEmpty) {
            try {
              final tileUrl = _getTileUrl(z, x, y);
              final response = await http.get(Uri.parse(tileUrl));

              if (response.statusCode == 200) {
                await db.insert(
                  'map_tiles',
                  {
                    'z': z,
                    'x': x,
                    'y': y,
                    'data': response.bodyBytes,
                  },
                );
              }
            } catch (e) {
              print('Cache tile error: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Cache map tiles error: $e');
    }
  }

  Future<Uint8List?> getOfflineTile(int z, int x, int y) async {
    if (!FeatureFlags.OFFLINE_MAP_CACHE) return null;

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
      print('Get offline tile error: $e');
      return null;
    }
  }

  Future<bool> isCached(List<List<double>> bounds) async {
    if (!FeatureFlags.OFFLINE_MAP_CACHE) return false;

    try {
      final db = await _getDatabase();
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM map_tiles WHERE z >= 13 AND z <= 15',
      );

      final count = (result.first['count'] as int?) ?? 0;
      return count > 50;
    } catch (e) {
      print('Is cached error: $e');
      return false;
    }
  }

  int _lngToTile(double lng, int z) {
    return ((lng + 180) / 360 * (1 << z)).toInt();
  }

  int _latToTile(double lat, int z) {
    final latRad = lat * 3.14159 / 180;
    return (((1 - (log(tan(latRad) + 1 / cos(latRad)) / 3.14159) / 2) *
                (1 << z))
            .toInt());
  }

  double log(double x) {
    return x > 0 ? (x * 0.693147 / 2.302585) : 0;
  }

  double tan(double rad) {
    final sinA = (rad * 2 - rad * rad * rad / 3) % 3.14159;
    final cosA = (1 - rad * rad / 2) % 3.14159;
    return sinA / cosA;
  }

  double cos(double rad) {
    return 1 - rad * rad / 2;
  }

  String _getTileUrl(int z, int x, int y) {
    return '${AppConfig.alsMapStyle}/tile/$z/$x/$y';
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
