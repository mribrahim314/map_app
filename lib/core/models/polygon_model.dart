import 'dart:convert';
import 'package:latlong2/latlong.dart';

/// Polygon model for PostgreSQL database
class PolygonModel {
  final int? id;
  final String district;
  final String gouvernante;
  final String type;
  final List<LatLng> coordinates;
  final String? message;
  final String? imageUrl;
  final String userId;
  final bool isAdopted;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PolygonModel({
    this.id,
    required this.district,
    required this.gouvernante,
    required this.type,
    required this.coordinates,
    this.message,
    this.imageUrl,
    required this.userId,
    required this.isAdopted,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  /// Create PolygonModel from database row
  factory PolygonModel.fromMap(Map<String, dynamic> map) {
    // Parse geometry GeoJSON
    List<LatLng> coords = [];
    if (map['geometry_geojson'] != null) {
      final geoJson = jsonDecode(map['geometry_geojson']);
      if (geoJson['type'] == 'Polygon' && geoJson['coordinates'] != null) {
        // GeoJSON coordinates are [longitude, latitude]
        final ring = geoJson['coordinates'][0] as List;
        coords = ring.map((coord) {
          return LatLng(coord[1] as double, coord[0] as double);
        }).toList();
      }
    }

    return PolygonModel(
      id: map['id'] as int?,
      district: map['district'] as String,
      gouvernante: map['gouvernante'] as String,
      type: map['type'] as String,
      coordinates: coords,
      message: map['message'] as String?,
      imageUrl: map['image_url'] as String?,
      userId: map['user_id'] as String,
      isAdopted: map['is_adopted'] as bool,
      date: map['date'] as DateTime,
      createdAt: map['created_at'] as DateTime?,
      updatedAt: map['updated_at'] as DateTime?,
    );
  }

  /// Convert coordinates to PostGIS POLYGON format
  /// Format: POLYGON((lng1 lat1, lng2 lat2, ..., lng1 lat1))
  String toPostGISPolygon() {
    if (coordinates.isEmpty) {
      throw Exception('Polygon must have at least 3 coordinates');
    }

    // Ensure polygon is closed (first point == last point)
    final coords = List<LatLng>.from(coordinates);
    if (coords.first.latitude != coords.last.latitude ||
        coords.first.longitude != coords.last.longitude) {
      coords.add(coords.first);
    }

    final coordStrings = coords.map((coord) {
      return '${coord.longitude} ${coord.latitude}';
    }).join(', ');

    return 'POLYGON(($coordStrings))';
  }

  /// Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'district': district,
      'gouvernante': gouvernante,
      'type': type,
      'geometry': toPostGISPolygon(),
      'message': message,
      'image_url': imageUrl,
      'user_id': userId,
      'is_adopted': isAdopted,
      'date': date,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  /// Create a copy with updated fields
  PolygonModel copyWith({
    int? id,
    String? district,
    String? gouvernante,
    String? type,
    List<LatLng>? coordinates,
    String? message,
    String? imageUrl,
    String? userId,
    bool? isAdopted,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PolygonModel(
      id: id ?? this.id,
      district: district ?? this.district,
      gouvernante: gouvernante ?? this.gouvernante,
      type: type ?? this.type,
      coordinates: coordinates ?? this.coordinates,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      isAdopted: isAdopted ?? this.isAdopted,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
