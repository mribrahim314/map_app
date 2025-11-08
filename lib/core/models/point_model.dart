import 'dart:convert';
import 'package:latlong2/latlong.dart';

/// Point model for PostgreSQL database
class PointModel {
  final int? id;
  final String district;
  final String gouvernante;
  final String type;
  final LatLng coordinate;
  final String? message;
  final String? imageUrl;
  final String userId;
  final bool isAdopted;
  final DateTime date;
  final String? parcelSize;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PointModel({
    this.id,
    required this.district,
    required this.gouvernante,
    required this.type,
    required this.coordinate,
    this.message,
    this.imageUrl,
    required this.userId,
    required this.isAdopted,
    required this.date,
    this.parcelSize,
    this.createdAt,
    this.updatedAt,
  });

  /// Create PointModel from database row
  factory PointModel.fromMap(Map<String, dynamic> map) {
    // Parse geometry GeoJSON
    LatLng coord = LatLng(0, 0);
    if (map['geometry_geojson'] != null) {
      final geoJson = jsonDecode(map['geometry_geojson']);
      if (geoJson['type'] == 'Point' && geoJson['coordinates'] != null) {
        // GeoJSON coordinates are [longitude, latitude]
        final coords = geoJson['coordinates'] as List;
        coord = LatLng(coords[1] as double, coords[0] as double);
      }
    }

    return PointModel(
      id: map['id'] as int?,
      district: map['district'] as String,
      gouvernante: map['gouvernante'] as String,
      type: map['type'] as String,
      coordinate: coord,
      message: map['message'] as String?,
      imageUrl: map['image_url'] as String?,
      userId: map['user_id'] as String,
      isAdopted: map['is_adopted'] as bool,
      date: map['date'] as DateTime,
      parcelSize: map['parcel_size'] as String?,
      createdAt: map['created_at'] as DateTime?,
      updatedAt: map['updated_at'] as DateTime?,
    );
  }

  /// Convert coordinate to PostGIS POINT format
  /// Format: POINT(lng lat)
  String toPostGISPoint() {
    return 'POINT(${coordinate.longitude} ${coordinate.latitude})';
  }

  /// Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'district': district,
      'gouvernante': gouvernante,
      'type': type,
      'geometry': toPostGISPoint(),
      'message': message,
      'image_url': imageUrl,
      'user_id': userId,
      'is_adopted': isAdopted,
      'date': date,
      'parcel_size': parcelSize,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  /// Create a copy with updated fields
  PointModel copyWith({
    int? id,
    String? district,
    String? gouvernante,
    String? type,
    LatLng? coordinate,
    String? message,
    String? imageUrl,
    String? userId,
    bool? isAdopted,
    DateTime? date,
    String? parcelSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PointModel(
      id: id ?? this.id,
      district: district ?? this.district,
      gouvernante: gouvernante ?? this.gouvernante,
      type: type ?? this.type,
      coordinate: coordinate ?? this.coordinate,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      isAdopted: isAdopted ?? this.isAdopted,
      date: date ?? this.date,
      parcelSize: parcelSize ?? this.parcelSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
