import 'package:map_app/core/networking/api_client.dart';

/// Service for managing polygons via the backend API
/// Polygons represent agricultural land parcels with coordinates
class PolygonService {
  final ApiClient _apiClient = ApiClient();

  /// Create a new polygon
  ///
  /// Parameters:
  /// - coordinates: List of coordinate pairs [[lng, lat], ...] forming the polygon
  /// - cropType: Type of crop in this parcel
  /// - area: Area in square meters
  /// - perimeter: Perimeter in meters
  /// - notes: Optional notes about the polygon
  /// - projectId: Optional project this polygon belongs to
  /// - images: Optional list of image URLs
  ///
  /// Returns the created polygon data
  Future<Map<String, dynamic>> createPolygon({
    required List<List<double>> coordinates,
    required String cropType,
    required double area,
    required double perimeter,
    String? notes,
    int? projectId,
    List<String>? images,
  }) async {
    try {
      final response = await _apiClient.post(
        '/polygons',
        body: {
          'coordinates': coordinates,
          'cropType': cropType,
          'area': area,
          'perimeter': perimeter,
          if (notes != null) 'notes': notes,
          if (projectId != null) 'projectId': projectId,
          if (images != null && images.isNotEmpty) 'images': images,
        },
      );

      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all polygons with optional filters
  ///
  /// Parameters:
  /// - page: Page number for pagination (default: 1)
  /// - limit: Number of items per page (default: 50)
  /// - cropType: Filter by crop type
  /// - projectId: Filter by project
  /// - userId: Filter by user
  /// - minArea: Minimum area in square meters
  /// - maxArea: Maximum area in square meters
  ///
  /// Returns paginated polygons data
  Future<Map<String, dynamic>> getAllPolygons({
    int page = 1,
    int limit = 50,
    String? cropType,
    int? projectId,
    int? userId,
    double? minArea,
    double? maxArea,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (cropType != null) 'cropType': cropType,
        if (projectId != null) 'projectId': projectId.toString(),
        if (userId != null) 'userId': userId.toString(),
        if (minArea != null) 'minArea': minArea.toString(),
        if (maxArea != null) 'maxArea': maxArea.toString(),
      };

      final response = await _apiClient.get(
        '/polygons',
        queryParams: queryParams,
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific polygon by ID
  ///
  /// Parameters:
  /// - id: The polygon ID
  ///
  /// Returns the polygon data
  Future<Map<String, dynamic>> getPolygonById(int id) async {
    try {
      final response = await _apiClient.get('/polygons/$id');
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing polygon
  ///
  /// Parameters:
  /// - id: The polygon ID to update
  /// - cropType: Updated crop type
  /// - notes: Updated notes
  /// - images: Updated image URLs
  ///
  /// Returns the updated polygon data
  Future<Map<String, dynamic>> updatePolygon({
    required int id,
    String? cropType,
    String? notes,
    List<String>? images,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (cropType != null) body['cropType'] = cropType;
      if (notes != null) body['notes'] = notes;
      if (images != null) body['images'] = images;

      final response = await _apiClient.put(
        '/polygons/$id',
        body: body,
      );

      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a polygon
  ///
  /// Parameters:
  /// - id: The polygon ID to delete
  ///
  /// Returns success status
  Future<bool> deletePolygon(int id) async {
    try {
      final response = await _apiClient.delete('/polygons/$id');
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  /// Get polygons within map bounds (spatial query)
  ///
  /// Parameters:
  /// - northEastLat: Northeast corner latitude
  /// - northEastLng: Northeast corner longitude
  /// - southWestLat: Southwest corner latitude
  /// - southWestLng: Southwest corner longitude
  /// - cropType: Optional filter by crop type
  /// - projectId: Optional filter by project
  /// - minArea: Optional minimum area filter
  /// - maxArea: Optional maximum area filter
  ///
  /// Returns list of polygons within the bounds
  Future<List<Map<String, dynamic>>> getPolygonsWithinBounds({
    required double northEastLat,
    required double northEastLng,
    required double southWestLat,
    required double southWestLng,
    String? cropType,
    int? projectId,
    double? minArea,
    double? maxArea,
  }) async {
    try {
      final body = {
        'northEast': {
          'lat': northEastLat,
          'lng': northEastLng,
        },
        'southWest': {
          'lat': southWestLat,
          'lng': southWestLng,
        },
        if (cropType != null) 'cropType': cropType,
        if (projectId != null) 'projectId': projectId,
        if (minArea != null) 'minArea': minArea,
        if (maxArea != null) 'maxArea': maxArea,
      };

      final response = await _apiClient.post(
        '/polygons/within-bounds',
        body: body,
      );

      final data = response['data'] as List;
      return data.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      rethrow;
    }
  }
}
