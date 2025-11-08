// ============================================================================
// CLEANED BY CLAUDE - Removed Firebase/Firestore dependencies
// ============================================================================

import 'dart:convert';
import 'package:map_app/core/repositories/polygon_repository.dart';
import 'package:map_app/core/repositories/point_repository.dart';
import 'package:map_app/core/repositories/user_repository.dart';

Future<String> generateFilteredGeoJson({
  required String polygonsCollection,
  required String pointsCollection,
  required String filtredCategory,
  required String filtredType,
  required String? userId,
}) async {
  final polygonRepo = PolygonRepository();
  final pointRepo = PointRepository();
  final List<Map<String, dynamic>> features = [];

  try {
    // Determine filter criteria
    bool? isAdoptedFilter;
    if (filtredType == "Shown data") {
      isAdoptedFilter = true;
    } else if (filtredType == "Non shown data") {
      isAdoptedFilter = false;
    }

    // --- FETCH POLYGONS ---
    List<dynamic> polygons;
    if (filtredType == "Specific User" && userId != null) {
      polygons = await polygonRepo.getPolygonsByUserId(userId);
    } else {
      polygons = await polygonRepo.getAllPolygons(isAdopted: isAdoptedFilter);
    }

    for (var polygon in polygons) {
      // Filter by category
      if (filtredCategory != "All" && polygon.type != filtredCategory) {
        continue;
      }

      List<List<double>> geoJsonCoords = polygon.coordinates.map((coord) {
        return [coord.longitude, coord.latitude];
      }).toList();

      if (geoJsonCoords.isEmpty) continue;

      String? userName = await getUsername(polygon.userId);

      final properties = {
        'District': polygon.district,
        'Gouvernante': polygon.gouvernante,
        'Type': polygon.type,
        'userId': polygon.userId,
        'Message': polygon.message,
        'imageURL': polygon.imageUrl,
        'Date': polygon.date?.toString(),
        'userName': userName,
      };

      features.add({
        "type": "Feature",
        "properties": properties,
        "geometry": {
          "type": "Polygon",
          "coordinates": [geoJsonCoords],
        },
      });
    }

    // --- FETCH POINTS ---
    List<dynamic> points;
    if (filtredType == "Specific User" && userId != null) {
      points = await pointRepo.getPointsByUserId(userId);
    } else {
      points = await pointRepo.getAllPoints(isAdopted: isAdoptedFilter);
    }

    // Group points by their properties
    final Map<String, Map<String, dynamic>> groupedProperties = {};
    final Map<String, List<List<double>>> groupedCoordinates = {};

    for (var point in points) {
      // Filter by category
      if (filtredCategory != "All" && point.type != filtredCategory) {
        continue;
      }

      List<double> lngLat = [
        point.coordinate.longitude,
        point.coordinate.latitude
      ];

      String? userName = await getUsername(point.userId);

      final properties = {
        'District': point.district,
        'Gouvernante': point.gouvernante,
        'Type': point.type,
        'userId': point.userId,
        'Message': point.message,
        'imageURL': point.imageUrl,
        'Date': point.date?.toString(),
        'userName': userName,
      };

      final key = jsonEncode(properties);

      groupedCoordinates.putIfAbsent(key, () => []);
      groupedProperties[key] = properties;
      groupedCoordinates[key]!.add(lngLat);
    }

    // Add MultiPoint features for each group
    for (var key in groupedCoordinates.keys) {
      features.add({
        "type": "Feature",
        "properties": groupedProperties[key]!,
        "geometry": {
          "type": "MultiPoint",
          "coordinates": groupedCoordinates[key]!,
        },
      });
    }

    // --- FINAL GEOJSON ---
    final geoJson = {"type": "FeatureCollection", "features": features};
    final jsonString = const JsonEncoder.withIndent('  ').convert(geoJson);
    return jsonString;
  } catch (e) {
    print('Error generating GeoJSON: $e');
    return '{"type": "FeatureCollection", "features": []}';
  }
}

Future<String?> findUserIdByEmail(String userEmail) async {
  try {
    final userRepo = UserRepository();
    final user = await userRepo.getUserByEmail(userEmail);
    return user?.id;
  } catch (e) {
    print('Error finding user by email: $e');
    return null;
  }
}

// Example function to get the username from userId
Future<String?> getUsername(String userId) async {
  try {
    final userRepo = UserRepository();
    final user = await userRepo.getUserById(userId);
    return user?.email ?? "Unknown";
  } catch (e) {
    print('Error fetching username: $e');
    return "Unknown";
  }
}
