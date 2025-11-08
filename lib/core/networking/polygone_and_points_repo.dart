import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maplibre/maplibre.dart';

class PolygonRepository {
  Future<List<Polygon>> fetchPolygonCoordinatesByType(
    String type,
    String collection,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where('Type', isEqualTo: type)
        .where('isAdopted', isEqualTo: true)
        .get();

    final polygons = snapshot.docs
        // Filtrer les documents sans coordonnées
        .where((doc) => (doc['coordinates'] as List).isNotEmpty)
        .map((doc) {
          final List<GeoPoint> coords = List<GeoPoint>.from(doc['coordinates']);
          if (coords.isEmpty) return null;

          final points = coords.map((geoPoint) {
            return Point(
              coordinates: Position(geoPoint.longitude, geoPoint.latitude),
            );
          }).toList();

          // Ne créer le polygone que si points n'est pas vide
          if (points.isEmpty) return null;
          return Polygon.fromPoints(points: [points]);
        })
        // Supprimer les null et forcer le type
        .whereType<Polygon>()
        .toList(); // Ici polygons est bien List<Polygon>

    return polygons;
  }

  // Future<List<Polygon>> fetchPolygonCoordinatesByType(
  //   String type,
  //   String collection,
  // ) async {
  //   // try {
  //   final snapshot = await FirebaseFirestore.instance
  //       .collection(collection)
  //       .where('Type', isEqualTo: type)
  //       .where('isAdopted', isEqualTo: true)
  //       .get();

  //   final List<Polygon> polygons = snapshot.docs.map((doc) {
  //     final List<GeoPoint> coords = List<GeoPoint>.from(doc['coordinates']);

  //     final points = coords.map((geoPoint) {
  //       return Point(
  //         coordinates: Position(geoPoint.longitude, geoPoint.latitude),
  //       );
  //     }).toList();

  //     return Polygon.fromPoints(points: [points]);
  //   }).toList();

  //   return polygons;
  //   // } catch (e) {
  //   //   print(e);
  //   //   return [];
  //   // }
  // }

  // Future<List<Polygon>> fetchPolygonCoordinatesByType(
  //   String type,
  //   String collection,
  // ) async {
  //   final snapshot = await FirebaseFirestore.instance
  //       .collection(collection)
  //       .where('Type', isEqualTo: type)
  //       .where('isAdopted', isEqualTo: true)
  //       .get();

  //   final List<Polygon> polygons = [];

  //   for (final doc in snapshot.docs) {
  //     print("\n==============================");
  //     print("📄 Document ID: ${doc.id}");
  //     print("🔹 Type: ${doc['Type']}");
  //     print("------------------------------");

  //     try {
  //       final List<GeoPoint> coords = List<GeoPoint>.from(doc['coordinates']);
  //       print("📍 Coordinates (${coords.length} points):");

  //       for (int i = 0; i < coords.length; i++) {
  //         print(
  //           "   [$i] lat: ${coords[i].latitude}, lon: ${coords[i].longitude}",
  //         );
  //       }

  //       final points = coords.map((geoPoint) {
  //         return Point(
  //           coordinates: Position(geoPoint.longitude, geoPoint.latitude),
  //         );
  //       }).toList();

  //       final polygon = Polygon.fromPoints(points: [points]);
  //       polygons.add(polygon);

  //       print("✅ Polygon created successfully.");
  //     } catch (e) {
  //       print("❌ Error parsing document ${doc.id}: $e");
  //     }
  //   }

  //   print("\n✅ Total polygons fetched: ${polygons.length}");
  //   print("==============================\n");

  //   return polygons;
  // }

  Future<List<Polygon>> fetchPolygonCoordinatesByTypeForCurrentUser(
    String type,
    String collection,
  ) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      throw Exception("User is not logged in");
    }

    final snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where('Type', isEqualTo: type)
        .where('userId', isEqualTo: currentUserId)
        .get();

    final List<Polygon> polygons = snapshot.docs.map((doc) {
      final List<GeoPoint> coords = List<GeoPoint>.from(doc['coordinates']);

      final points = coords.map((geoPoint) {
        return Point(
          coordinates: Position(geoPoint.longitude, geoPoint.latitude),
        );
      }).toList();

      return Polygon.fromPoints(points: [points]);
    }).toList();

    return polygons;
  }
}

class PointsRepository {
  Future<List<Position>> fetchPointsByType(
    String type,
    String collection,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where('Type', isEqualTo: type)
          .where('isAdopted', isEqualTo: true)
          .get();

      final List<Position> points = snapshot.docs.expand((doc) {
        final List<GeoPoint> coords = List<GeoPoint>.from(doc['coordinates']);
        return coords.map(
          (geoPoint) => Position(geoPoint.longitude, geoPoint.latitude),
        );
      }).toList();

      return points;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<Position>> fetchPointsByTypeForCurrentUser(
    String type,
    String collection,
  ) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      throw Exception("User is not logged in");
    }

    final snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where('Type', isEqualTo: type)
        .where('userId', isEqualTo: currentUserId)
        .get();

    final List<Position> points = snapshot.docs.expand((doc) {
      final List<GeoPoint> coords = List<GeoPoint>.from(doc['coordinates']);
      return coords.map(
        (geoPoint) => Position(geoPoint.longitude, geoPoint.latitude),
      );
    }).toList();

    return points;
  }
}
