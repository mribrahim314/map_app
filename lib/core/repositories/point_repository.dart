import '../database/database_service.dart';
import '../models/point_model.dart';

/// Repository for point database operations
class PointRepository {
  final DatabaseService _db = DatabaseService.instance;

  /// Create a new point
  Future<PointModel> createPoint(PointModel point) async {
    final result = await _db.query(
      '''
      INSERT INTO points (
        district, gouvernante, type, geometry, message, image_url,
        user_id, is_adopted, date, parcel_size
      )
      VALUES (
        @district, @gouvernante, @type, ST_GeomFromText(@geometry, 4326),
        @message, @image_url, @user_id, @is_adopted, @date, @parcel_size
      )
      RETURNING id, district, gouvernante, type, ST_AsGeoJSON(geometry) as geometry_geojson,
                message, image_url, user_id, is_adopted, date, parcel_size, created_at, updated_at
      ''',
      parameters: {
        'district': point.district,
        'gouvernante': point.gouvernante,
        'type': point.type,
        'geometry': point.toPostGISPoint(),
        'message': point.message,
        'image_url': point.imageUrl,
        'user_id': point.userId,
        'is_adopted': point.isAdopted,
        'date': point.date,
        'parcel_size': point.parcelSize,
      },
    );

    if (result.isEmpty) {
      throw Exception('Failed to create point');
    }

    return PointModel.fromMap(result.first.toColumnMap());
  }

  /// Get point by ID
  Future<PointModel?> getPointById(int id) async {
    final result = await _db.query(
      '''
      SELECT id, district, gouvernante, type, ST_AsGeoJSON(geometry) as geometry_geojson,
             message, image_url, user_id, is_adopted, date, parcel_size, created_at, updated_at
      FROM points
      WHERE id = @id
      ''',
      parameters: {'id': id},
    );

    if (result.isEmpty) {
      return null;
    }

    return PointModel.fromMap(result.first.toColumnMap());
  }

  /// Get points by type
  Future<List<PointModel>> getPointsByType({
    required String type,
    bool? isAdopted,
  }) async {
    String query = '''
      SELECT id, district, gouvernante, type, ST_AsGeoJSON(geometry) as geometry_geojson,
             message, image_url, user_id, is_adopted, date, parcel_size, created_at, updated_at
      FROM points
      WHERE type = @type
    ''';

    Map<String, dynamic> params = {'type': type};

    if (isAdopted != null) {
      query += ' AND is_adopted = @is_adopted';
      params['is_adopted'] = isAdopted;
    }

    query += ' ORDER BY date DESC';

    final result = await _db.query(query, parameters: params);
    return result.map((row) => PointModel.fromMap(row.toColumnMap())).toList();
  }

  /// Get points by user ID
  Future<List<PointModel>> getPointsByUserId(String userId) async {
    final result = await _db.query(
      '''
      SELECT id, district, gouvernante, type, ST_AsGeoJSON(geometry) as geometry_geojson,
             message, image_url, user_id, is_adopted, date, parcel_size, created_at, updated_at
      FROM points
      WHERE user_id = @userId
      ORDER BY date DESC
      ''',
      parameters: {'userId': userId},
    );

    return result.map((row) => PointModel.fromMap(row.toColumnMap())).toList();
  }

  /// Get all points
  Future<List<PointModel>> getAllPoints({bool? isAdopted}) async {
    String query = '''
      SELECT id, district, gouvernante, type, ST_AsGeoJSON(geometry) as geometry_geojson,
             message, image_url, user_id, is_adopted, date, parcel_size, created_at, updated_at
      FROM points
    ''';

    Map<String, dynamic> params = {};

    if (isAdopted != null) {
      query += ' WHERE is_adopted = @is_adopted';
      params['is_adopted'] = isAdopted;
    }

    query += ' ORDER BY date DESC';

    final result = await _db.query(query, parameters: params);
    return result.map((row) => PointModel.fromMap(row.toColumnMap())).toList();
  }

  /// Update point
  Future<void> updatePoint(int id, PointModel point) async {
    await _db.query(
      '''
      UPDATE points
      SET district = @district,
          gouvernante = @gouvernante,
          type = @type,
          geometry = ST_GeomFromText(@geometry, 4326),
          message = @message,
          image_url = @image_url,
          is_adopted = @is_adopted,
          date = @date,
          parcel_size = @parcel_size,
          updated_at = NOW()
      WHERE id = @id
      ''',
      parameters: {
        'id': id,
        'district': point.district,
        'gouvernante': point.gouvernante,
        'type': point.type,
        'geometry': point.toPostGISPoint(),
        'message': point.message,
        'image_url': point.imageUrl,
        'is_adopted': point.isAdopted,
        'date': point.date,
        'parcel_size': point.parcelSize,
      },
    );
  }

  /// Update point adoption status
  Future<void> updateAdoptionStatus(int id, bool isAdopted) async {
    await _db.query(
      '''
      UPDATE points
      SET is_adopted = @is_adopted, updated_at = NOW()
      WHERE id = @id
      ''',
      parameters: {
        'id': id,
        'is_adopted': isAdopted,
      },
    );
  }

  /// Delete point
  Future<void> deletePoint(int id) async {
    await _db.query(
      'DELETE FROM points WHERE id = @id',
      parameters: {'id': id},
    );
  }

  /// Delete all points by user ID
  Future<void> deletePointsByUserId(String userId) async {
    await _db.query(
      'DELETE FROM points WHERE user_id = @userId',
      parameters: {'userId': userId},
    );
  }

  /// Get points within bounding box
  Future<List<PointModel>> getPointsInBBox({
    required double minLng,
    required double minLat,
    required double maxLng,
    required double maxLat,
    String? type,
    bool isAdopted = true,
  }) async {
    final result = await _db.query(
      '''
      SELECT * FROM get_points_in_bbox(
        @minLng, @minLat, @maxLng, @maxLat, @type, @isAdopted
      )
      ''',
      parameters: {
        'minLng': minLng,
        'minLat': minLat,
        'maxLng': maxLng,
        'maxLat': maxLat,
        'type': type,
        'isAdopted': isAdopted,
      },
    );

    return result.map((row) => PointModel.fromMap(row.toColumnMap())).toList();
  }

  /// Get count of points by user
  Future<int> getPointCountByUser(String userId) async {
    final result = await _db.query(
      'SELECT COUNT(*) as count FROM points WHERE user_id = @userId',
      parameters: {'userId': userId},
    );

    return result.first.toColumnMap()['count'] as int;
  }
}
