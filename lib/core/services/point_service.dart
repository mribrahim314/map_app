import 'package:map_app/core/networking/api_client.dart';

/// Service for managing points via the backend API
/// Points represent individual crop locations with coordinates
class PointService {
  final ApiClient _apiClient = ApiClient();

  /// Create a new point
  ///
  /// Parameters:
  /// - latitude: Point latitude coordinate
  /// - longitude: Point longitude coordinate
  /// - cropType: Type of crop at this location
  /// - notes: Optional notes about the point
  /// - projectId: Optional project this point belongs to
  /// - images: Optional list of image URLs
  ///
  /// Returns the created point data
  Future<Map<String, dynamic>> createPoint({
    required double latitude,
    required double longitude,
    required String cropType,
    String? notes,
    int? projectId,
    List<String>? images,
  }) async {
    try {
      final response = await _apiClient.post(
        '/points',
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'cropType': cropType,
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

  /// Get all points with optional filters
  ///
  /// Parameters:
  /// - page: Page number for pagination (default: 1)
  /// - limit: Number of items per page (default: 50)
  /// - cropType: Filter by crop type
  /// - projectId: Filter by project
  /// - userId: Filter by user
  ///
  /// Returns paginated points data
  Future<Map<String, dynamic>> getAllPoints({
    int page = 1,
    int limit = 50,
    String? cropType,
    int? projectId,
    int? userId,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (cropType != null) 'cropType': cropType,
        if (projectId != null) 'projectId': projectId.toString(),
        if (userId != null) 'userId': userId.toString(),
      };

      final response = await _apiClient.get(
        '/points',
        queryParams: queryParams,
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific point by ID
  ///
  /// Parameters:
  /// - id: The point ID
  ///
  /// Returns the point data
  Future<Map<String, dynamic>> getPointById(int id) async {
    try {
      final response = await _apiClient.get('/points/$id');
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing point
  ///
  /// Parameters:
  /// - id: The point ID to update
  /// - cropType: Updated crop type
  /// - notes: Updated notes
  /// - images: Updated image URLs
  ///
  /// Returns the updated point data
  Future<Map<String, dynamic>> updatePoint({
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
        '/points/$id',
        body: body,
      );

      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a point
  ///
  /// Parameters:
  /// - id: The point ID to delete
  ///
  /// Returns success status
  Future<bool> deletePoint(int id) async {
    try {
      final response = await _apiClient.delete('/points/$id');
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  /// Get points within map bounds (spatial query)
  ///
  /// Parameters:
  /// - northEastLat: Northeast corner latitude
  /// - northEastLng: Northeast corner longitude
  /// - southWestLat: Southwest corner latitude
  /// - southWestLng: Southwest corner longitude
  /// - cropType: Optional filter by crop type
  /// - projectId: Optional filter by project
  ///
  /// Returns list of points within the bounds
  Future<List<Map<String, dynamic>>> getPointsWithinBounds({
    required double northEastLat,
    required double northEastLng,
    required double southWestLat,
    required double southWestLng,
    String? cropType,
    int? projectId,
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
      };

      final response = await _apiClient.post(
        '/points/within-bounds',
        body: body,
      );

      final data = response['data'] as List;
      return data.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      rethrow;
    }
  }
}
