import 'dart:io';

import 'package:hive/hive.dart';
import 'package:map_app/core/services/upload_image_to_supabase.dart';
import 'package:map_app/core/repositories/polygon_repository.dart';
import 'package:map_app/core/repositories/point_repository.dart';
import 'package:map_app/core/repositories/user_repository.dart';
import 'package:map_app/core/models/point_model.dart';
import 'package:map_app/core/models/polygon_model.dart';
import 'package:latlong2/latlong.dart';

part 'pending_submission.g.dart';

@HiveType(typeId: 0)
class PendingSubmission extends HiveObject {
  @HiveField(0)
  String? district;

  @HiveField(1)
  String? gouvernante;

  @HiveField(2)
  dynamic coordinates;

  @HiveField(3)
  String? type;

  @HiveField(4)
  String? message;

  @HiveField(5)
  String? imageURL;

  @HiveField(6)
  String userId;

  @HiveField(7)
  bool isAdopted;

  @HiveField(8)
  String? parcelSize;

  @HiveField(9)
  String date;

  @HiveField(10)
  String collection;

  PendingSubmission({
    required this.district,
    required this.gouvernante,
    required this.coordinates,
    required this.type,
    required this.message,
    required this.imageURL,
    required this.userId,
    required this.isAdopted,
    this.parcelSize,
    required this.date,
    required this.collection,
  });
}

String getTargetCollection(bool isPoint, String userRole) {
  return isPoint ? 'points' : 'polygones';
}

/// Send all pending submissions to PostgreSQL database
Future<void> sendPendingSubmissions() async {
  final box = await Hive.openBox<PendingSubmission>('pendingSubmissions');
  final submissions = box.values.toList();

  if (submissions.isEmpty) return;

  final polygonRepo = PolygonRepository();
  final pointRepo = PointRepository();
  final userRepo = UserRepository();

  for (var i = 0; i < submissions.length; i++) {
    final sub = submissions[i];

    String? uploadedImageUrl;

    // Upload image if exists
    if (sub.imageURL != null) {
      final file = File(sub.imageURL!);
      if (await file.exists()) {
        try {
          uploadedImageUrl = await uploadImageToSupabase(file);
        } catch (e) {
          print("Failed to upload image for pending submission: $e");
          continue; // Skip this submission for now
        }
      }
    }

    // Convert coordinates to proper format
    final coords = (sub.coordinates as List).map((coord) {
      return {
        'lat': coord['lat'] as double,
        'lng': coord['lng'] as double,
      };
    }).toList();

    try {
      // Send to PostgreSQL based on collection type
      if (sub.collection == 'points') {
        // For points, expect single coordinate
        if (coords.isNotEmpty) {
          final point = PointModel(
            district: sub.district ?? '',
            gouvernante: sub.gouvernante ?? '',
            type: sub.type ?? '',
            coordinate: LatLng(coords[0]['lat']!, coords[0]['lng']!),
            message: sub.message,
            imageUrl: uploadedImageUrl,
            userId: sub.userId,
            isAdopted: sub.isAdopted,
            date: DateTime.parse(sub.date),
            parcelSize: sub.parcelSize,
          );
          await pointRepo.createPoint(point, district: sub.district ?? '');
        }
      } else if (sub.collection == 'polygones') {
        // For polygons, expect multiple coordinates
        final coordinates = coords.map((coord) {
          return LatLng(coord['lat']!, coord['lng']!);
        }).toList();

        final polygon = PolygonModel(
          district: sub.district ?? '',
          gouvernante: sub.gouvernante ?? '',
          type: sub.type ?? '',
          coordinates: coordinates,
          message: sub.message,
          imageUrl: uploadedImageUrl,
          userId: sub.userId,
          isAdopted: sub.isAdopted,
          date: DateTime.parse(sub.date),
        );
        await polygonRepo.createPolygon(polygon);
      }

      // Increment user contribution count
      await userRepo.incrementContributionCount(sub.userId);

      print("Pending submission uploaded successfully");

      // Remove from Hive after successful upload
      await box.deleteAt(i);
      i--; // Adjust index because we removed one
    } catch (e) {
      print("Failed to send pending submission: $e");
      // Keep the submission in the queue for retry
    }
  }
}
