import '../database/database_service.dart';
import '../models/polygon_model.dart';

/// Repository for polygon database operations
class PolygonRepository {
  final DatabaseService _db = DatabaseService.instance;

  /// Create a new polygon
  Future<PolygonModel> createPolygon(PolygonModel polygon) async {
    final result = await _db.query(
      '''
      INSERT INTO polygones (
        district, gouvernante, type, geometry, message, image_url,
        user_id, is_adopted, date
      )
      VALUES (
        @district, @gouvernante, @type, ST_GeomFromText(@geometry, 4326),
        @message, @image_url, @user_id, @is_adopted, @date
      )
      RETURNING id, district, gouvernante, type, ST_AsGeoJSON(geometry) as geometry_geojson,
                message, image_url, user_id, is_adopted, date, created_at, updated_at
      ''',
      parameters: {
        'district': polygon.district,
        'gouvernante': polygon.gouvernante,
        'type': polygon.type,
        'geometry': polygon.toPostGISPolygon(),
        'message': polygon.message,
        'image_url': polygon.imageUrl,
        'user_id': polygon.userId,
        'is_adopted': polygon.isAdopted,
        'date': polygon.date,
      },
    );

    if (result.isEmpty) {
      throw Exception('Failed to create polygon');
    }

    return PolygonModel.fromMap(result.first.toColumnMap());
  }

  /// Get polygon by ID
  Future<PolygonModel?> getPolygonById(int id) async {
    final result = await _db.query(
      '''
      SELECT id, district, gouvernante, type, ST_AsGeoJSON(geometry) as geometry_geojson,
             message, image_url, user_id, is_adopted, date, created_at, updated_at
      FROM polygones
      WHERE id = @id
      ''',
      parameters: {'id': id},
    );

    if (result.isEmpty) {
      return null;
    }

    return PolygonModel.fromMap(result.first.toColumnMap());
  }

  /// Get polygons by type
  Future<List<PolygonModel>> getPolygonsByType({
    required String type,
    bool? isAdopted,
  }) async {
    String query = '''
      SELECT id, district, gouvernante, type, ST_AsGeoJSON(geometry) as geometry_geojson,
             message, image_url, user_id, is_adopted, date, created_at, updated_at
      FROM polygones
      WHERE type = @type
    ''';

    Map<String, dynamic> params = {'type': type};

    if (isAdopted != null) {
      query += ' AND is_adopted = @is_adopted';
      params['is_adopted'] = isAdopted;
    }

    query += ' ORDER BY date DESC';

    final result = await _db.query(query, parameters: params);
    return result.map((row) => PolygonModel.fromMap(row.toColumnMap())).toList();
  }

  /// Get polygons by user ID
  Future<List<PolygonModel>> getPolygonsByUserId(String userId) async {
    final result = await _db.query(
      '''
      SELECT id, district, gouvernante, type, ST_AsGeoJSON(geometry) as geometry_geojson,
             message, image_url, user_id, is_adopted, date, created_at, updated_at
      FROM polygones
      WHERE user_id = @userId
      ORDER BY date DESC
      ''',
      parameters: {'userId': userId},
    );

    return result.map((row) => PolygonModel.fromMap(row.toColumnMap())).toList();
  }

  /// Get all polygons
  Future<List<PolygonModel>> getAllPolygons({bool? isAdopted}) async {
    String query = '''
      SELECT id, district, gouvernante, type, ST_AsGeoJSON(geometry) as geometry_geojson,
             message, image_url, user_id, is_adopted, date, created_at, updated_at
      FROM polygones
    ''';

    Map<String, dynamic> params = {};

    if (isAdopted != null) {
      query += ' WHERE is_adopted = @is_adopted';
      params['is_adopted'] = isAdopted;
    }

    query += ' ORDER BY date DESC';

    final result = await _db.query(query, parameters: params);
    return result.map((row) => PolygonModel.fromMap(row.toColumnMap())).toList();
  }

  /// Update polygon
  Future<void> updatePolygon(int id, PolygonModel polygon) async {
    await _db.query(
      '''
      UPDATE polygones
      SET district = @district,
          gouvernante = @gouvernante,
          type = @type,
          geometry = ST_GeomFromText(@geometry, 4326),
          message = @message,
          image_url = @image_url,
          is_adopted = @is_adopted,
          date = @date,
          updated_at = NOW()
      WHERE id = @id
      ''',
      parameters: {
        'id': id,
        'district': polygon.district,
        'gouvernante': polygon.gouvernante,
        'type': polygon.type,
        'geometry': polygon.toPostGISPolygon(),
        'message': polygon.message,
        'image_url': polygon.imageUrl,
        'is_adopted': polygon.isAdopted,
        'date': polygon.date,
      },
    );
  }

  /// Update polygon adoption status
  Future<void> updateAdoptionStatus(int id, bool isAdopted) async {
    await _db.query(
      '''
      UPDATE polygones
      SET is_adopted = @is_adopted, updated_at = NOW()
      WHERE id = @id
      ''',
      parameters: {
        'id': id,
        'is_adopted': isAdopted,
      },
    );
  }

  /// Delete polygon
  Future<void> deletePolygon(int id) async {
    await _db.query(
      'DELETE FROM polygones WHERE id = @id',
      parameters: {'id': id},
    );
  }

  /// Delete all polygons by user ID
  Future<void> deletePolygonsByUserId(String userId) async {
    await _db.query(
      'DELETE FROM polygones WHERE user_id = @userId',
      parameters: {'userId': userId},
    );
  }

  /// Get polygons within bounding box
  Future<List<PolygonModel>> getPolygonsInBBox({
    required double minLng,
    required double minLat,
    required double maxLng,
    required double maxLat,
    String? type,
    bool isAdopted = true,
  }) async {
    final result = await _db.query(
      '''
      SELECT * FROM get_polygones_in_bbox(
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

    return result.map((row) => PolygonModel.fromMap(row.toColumnMap())).toList();
  }

  /// Get count of polygons by user
  Future<int> getPolygonCountByUser(String userId) async {
    final result = await _db.query(
      'SELECT COUNT(*) as count FROM polygones WHERE user_id = @userId',
      parameters: {'userId': userId},
    );

    return result.first.toColumnMap()['count'] as int;
  }
}
