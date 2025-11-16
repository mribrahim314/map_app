// ============================================================================
// Compatibility layer for backend API integration
// Wraps PointService and PolygonService to maintain compatibility with old code
// ============================================================================

import 'package:maplibre/maplibre.dart';
import 'package:map_app/core/services/point_service.dart';
import 'package:map_app/core/services/polygon_service.dart';
import 'package:map_app/core/services/auth_service.dart';

/// Wrapper for PointService to maintain compatibility with old code
class PointsRepository {
  final PointService _service = PointService();
  final AuthService _authService = AuthService();

  /// Fetch points by type and convert to Position list
  Future<List<Position>> fetchPointsByType(String type, String collection) async {
    try {
      final response = await _service.getAllPoints(cropType: type, limit: 1000);
      final points = response['data'] as List;

      return points.map((point) {
        final geometry = point['geometry'] as Map<String, dynamic>;
        final coordinates = geometry['coordinates'] as List;
        // GeoJSON format: [longitude, latitude]
        return Position(coordinates[0] as double, coordinates[1] as double);
      }).toList();
    } catch (e) {
      print('Error fetching points by type: $e');
      return [];
    }
  }

  /// Fetch points by type for current user and convert to Position list
  Future<List<Position>> fetchPointsByTypeForCurrentUser(String type, String collection) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        print('No user logged in');
        return [];
      }

      final response = await _service.getAllPoints(
        cropType: type,
        userId: user.id,
        limit: 1000,
      );
      final points = response['data'] as List;

      return points.map((point) {
        final geometry = point['geometry'] as Map<String, dynamic>;
        final coordinates = geometry['coordinates'] as List;
        // GeoJSON format: [longitude, latitude]
        return Position(coordinates[0] as double, coordinates[1] as double);
      }).toList();
    } catch (e) {
      print('Error fetching points for current user: $e');
      return [];
    }
  }
}

/// Wrapper for PolygonService to maintain compatibility with old code
class PolygonRepository {
  final PolygonService _service = PolygonService();
  final AuthService _authService = AuthService();

  /// Fetch polygon coordinates by type and convert to Polygon list
  Future<List<Polygon>> fetchPolygonCoordinatesByType(String type, String collection) async {
    try {
      final response = await _service.getAllPolygons(cropType: type, limit: 1000);
      final polygons = response['data'] as List;

      return polygons.map((polygon) {
        final geometry = polygon['geometry'] as Map<String, dynamic>;
        final coordinates = geometry['coordinates'] as List;
        // GeoJSON format: [[[lng, lat], ...]]
        final ring = coordinates[0] as List;
        final positions = ring.map((coord) {
          final coords = coord as List;
          return Position(coords[0] as double, coords[1] as double);
        }).toList();

        return Polygon(coordinates: [positions]);
      }).toList();
    } catch (e) {
      print('Error fetching polygons by type: $e');
      return [];
    }
  }

  /// Fetch polygon coordinates by type for current user and convert to Polygon list
  Future<List<Polygon>> fetchPolygonCoordinatesByTypeForCurrentUser(String type, String collection) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        print('No user logged in');
        return [];
      }

      final response = await _service.getAllPolygons(
        cropType: type,
        userId: user.id,
        limit: 1000,
      );
      final polygons = response['data'] as List;

      return polygons.map((polygon) {
        final geometry = polygon['geometry'] as Map<String, dynamic>;
        final coordinates = geometry['coordinates'] as List;
        // GeoJSON format: [[[lng, lat], ...]]
        final ring = coordinates[0] as List;
        final positions = ring.map((coord) {
          final coords = coord as List;
          return Position(coords[0] as double, coords[1] as double);
        }).toList();

        return Polygon(coordinates: [positions]);
      }).toList();
    } catch (e) {
      print('Error fetching polygons for current user: $e');
      return [];
    }
  }
}
