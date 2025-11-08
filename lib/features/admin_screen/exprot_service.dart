import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

Future<String> generateFilteredGeoJson({
  required String polygonsCollection,
  required String pointsCollection,
  required String filtredCategory, // filter on this type field (exact match)
  required String filtredType, // filter on this type field (exact match)
  required String? userId, // filter on this type field (exact match)
}) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> features = [];

  Map<String, dynamic> buildProperties(
    Map<String, dynamic> data,
    List<String> fields,
  ) {
    final Map<String, dynamic> props = {};
    for (final field in fields) {
      final value = data[field];
      if (value != null) {
        props[field] = value;
      }
    }
    return props;
  }

  // --- FETCH POLYGONS ---
  final polySnapshot = await firestore.collection(polygonsCollection).get();
  for (var doc in polySnapshot.docs) {
    final data = doc.data();

    // Filter by type field
    if (filtredCategory != "All" && data['Type'] != filtredCategory) {
      continue;
    }
    if (filtredType == "Shown data" && data['isAdopted'] == false) continue;
    if (filtredType == "Non shown data" && data['isAdopted'] == true) continue;
    if (filtredType == "Specific User" && data['userId'] != userId) continue;

    final rawCoords = data['coordinates'];
    if (rawCoords == null || rawCoords.length < 3) continue;

    List<List<double>> geoJsonCoords = [];

    for (var coord in rawCoords) {
      if (coord is GeoPoint) {
        geoJsonCoords.add([
          coord.longitude.toDouble(),
          coord.latitude.toDouble(),
        ]);
      } else if (coord is List && coord.length == 2) {
        geoJsonCoords.add([
          (coord[1] as num).toDouble(),
          (coord[0] as num).toDouble(),
        ]);
      } else {
        continue; // invalid coord format
      }
    }

    if (geoJsonCoords.isEmpty) continue;

    // Ensure polygon is closed
    // if (geoJsonCoords.first[0] != geoJsonCoords.last[0] ||
    //     geoJsonCoords.first[1] != geoJsonCoords.last[1]) {
    //   geoJsonCoords.add(geoJsonCoords.first);
    // }

    final properties = buildProperties(data, [
      'District',
      'Gouvernante',
      'Type',
      'userId',
      'Message',

      'imageURL',
      'Date',
    ]);
    String? _userName = await getUsername(data['userId']);
    properties['userName'] = _userName;

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
  final pointSnapshot = await firestore.collection(pointsCollection).get();

  // Group points by their properties (filtered by type)
  final Map<String, Map<String, dynamic>> groupedProperties = {};
  final Map<String, List<List<double>>> groupedCoordinates = {};

  for (var doc in pointSnapshot.docs) {
    final data = doc.data();

    if (filtredCategory != "All" && data['Type'] != filtredCategory) {
      continue;
    }
    if (filtredType == "Shown data" && data['isAdopted'] == false) continue;
    if (filtredType == "Non shown data" && data['isAdopted'] == true) continue;
    if (filtredType == "Specific User" && data['userId'] != userId) continue;

    final coord = data['coordinates'][0];
    List<double>? lngLat;

    if (coord is GeoPoint) {
      lngLat = [coord.longitude.toDouble(), coord.latitude.toDouble()];
    } else if (coord is List && coord.length == 2) {
      lngLat = [(coord[1] as num).toDouble(), (coord[0] as num).toDouble()];
    }

    if (lngLat == null) continue;

    final properties = buildProperties(data, [
      'District',
      'Gouvernante',
      'Type',
      'userId',
      'Message',

      'imageURL',
      'Date',
    ]);

    String? _userName = await getUsername(data['userId']);
    print(_userName);
    properties['userName'] = _userName;

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
}

Future<String?> findUserIdByEmail(String userEmail) async {
  final users = FirebaseFirestore.instance.collection('users');

  final query = await users.where('email', isEqualTo: userEmail).limit(1).get();

  if (query.docs.isEmpty) return null;

  return query.docs.first.id;
}

// Example function to get the username from userId
Future<String?> getUsername(String userId) async {
  try {
    // Reference to the user document
    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      // Access the userName field
      final data = docSnapshot.data();
      final username = data?['email'] as String?;
      return username;
    } else {
      print('User not found');
      return "Unknown";
    }
  } catch (e) {
    print('Error fetching username: $e');
    return null;
  }
}
