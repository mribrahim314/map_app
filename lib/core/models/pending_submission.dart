import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:map_app/core/services/upload_image_to_supabase.dart';

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

Future<void> sendPendingSubmissions() async {
  final box = await Hive.openBox<PendingSubmission>('pendingSubmissions');
  final submissions = box.values.toList();

  if (submissions.isEmpty) return;

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
    final firestoreCoordinates = sub.coordinates.map((coord) {
      return GeoPoint(coord['lat'], coord['lng']);
    }).toList();
    // Send to Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection(sub.collection)
          .add({
            "District": sub.district,
            "Gouvernante": sub.gouvernante,
            "coordinates": firestoreCoordinates,
            "Type": sub.type,
            "Message": sub.message,
            "imageURL": uploadedImageUrl,
            "userId": sub.userId,
            "isAdopted": sub.isAdopted,
            "parcelSize": sub.parcelSize,
            "Date": sub.date,
          });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(sub.userId)
          .update({'contributionCount': FieldValue.increment(1)});
      print("Pending submission uploaded: ${doc.id}");

      // Remove from Hive after successful upload
      await box.deleteAt(i);
      i--; // adjust index because we removed one
    } catch (e) {
      print("Failed to send pending submission: $e");
    }
  }
}
