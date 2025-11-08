// ============================================================================
// CREATED BY CLAUDE - Compatibility layer for old Firebase-style repository
// ============================================================================

import 'package:maplibre/maplibre.dart';
import 'package:map_app/core/repositories/point_repository.dart';
import 'package:map_app/core/repositories/polygon_repository.dart' as repo;
import 'package:map_app/core/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wrapper for PointRepository to maintain compatibility with old code
class PointsRepository {
  final PointRepository _repo = PointRepository();

  /// Fetch points by type and convert to Position list
  Future<List<Position>> fetchPointsByType(String type, String collection) async {
    try {
      final points = await _repo.getPointsByType(type: type, isAdopted: true);
      return points.map((point) {
        return Position(point.coordinate.longitude, point.coordinate.latitude);
      }).toList();
    } catch (e) {
      print('Error fetching points by type: $e');
      return [];
    }
  }

  /// Fetch points by type for current user and convert to Position list
  Future<List<Position>> fetchPointsByTypeForCurrentUser(String type, String collection) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('No user logged in');
        return [];
      }

      final allPoints = await _repo.getPointsByUserId(userId);
      final filteredPoints = allPoints.where((p) => p.type == type).toList();

      return filteredPoints.map((point) {
        return Position(point.coordinate.longitude, point.coordinate.latitude);
      }).toList();
    } catch (e) {
      print('Error fetching points for current user: $e');
      return [];
    }
  }
}

/// Wrapper for PolygonRepository to maintain compatibility with old code
class PolygonRepository {
  final _repo = repo.PolygonRepository();

  /// Fetch polygon coordinates by type and convert to Polygon list
  Future<List<Polygon>> fetchPolygonCoordinatesByType(String type, String collection) async {
    try {
      final polygons = await _repo.getPolygonsByType(type: type, isAdopted: true);
      return polygons.map((polygon) {
        final positions = polygon.coordinates.map((coord) {
          return Position(coord.longitude, coord.latitude);
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
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('No user logged in');
        return [];
      }

      final allPolygons = await _repo.getPolygonsByUserId(userId);
      final filteredPolygons = allPolygons.where((p) => p.type == type).toList();

      return filteredPolygons.map((polygon) {
        final positions = polygon.coordinates.map((coord) {
          return Position(coord.longitude, coord.latitude);
        }).toList();

        return Polygon(coordinates: [positions]);
      }).toList();
    } catch (e) {
      print('Error fetching polygons for current user: $e');
      return [];
    }
  }
}
