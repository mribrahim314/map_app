import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:map_app/core/cubit/coordinates_cubit.dart';
import 'package:map_app/core/cubit/polygone_cubit.dart';
import 'package:map_app/core/models/pending_submission.dart';
import 'package:map_app/features/admin_user_screen/widgets/polygon_point_card.dart';
import 'package:map_app/features/admin_user_screen/screens/map_screen_with_appbar.dart';
import 'package:map_app/features/map_page/map_screen.dart';
import 'package:maplibre/maplibre.dart';

Widget buildOfflineUnifiedList({
  required BuildContext context,
  required String emptyText,
}) {
  return FutureBuilder<Box<PendingSubmission>>(
    future: Hive.openBox<PendingSubmission>('pendingSubmissions'),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Error loading data: ${snapshot.error}'));
      }

      final box = snapshot.data!;
      final List<PendingSubmission> items = box.values.toList();

      if (items.isEmpty) {
        return Center(
          child: Text(emptyText, style: TextStyle(color: Colors.grey[600])),
        );
      }

      return SizedBox(
        height: 400,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final keys = box.keys.toList();
            final key = keys[index];

            final isPolygon = item.coordinates.length > 1;
            final isAdopted = item.isAdopted;
            final adoptText = isAdopted ? "Retrieve" : "Adopt";

            // Mimic Firestore document data structure for the card
            final Map<String, dynamic> itemData = {
              'district': item.district,
              'gouvernante': item.gouvernante,
              'coordinates': item.coordinates,
              'Type': item.type,
              'message': item.message,
              'imageURL': item.imageURL,
              'userId': item.userId,
              'isAdopted': isAdopted,
              'parcelSize': item.parcelSize,
              'date': item.date,
            };

            return PolygonPointCard(
              noNet: true,
              polygonId: key.toString(),
              onDelete: () async {
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Confirmation"),
                      content: const Text(
                        "Are you sure you want to delete this submission?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await box.deleteAt(key);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Deleted successfully"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              adoptText: adoptText,
              data: itemData,
              onAdopt: () async {},
              onViewMap: () {
                final List<GeoPoint> coords = item.coordinates;

                if (isPolygon) {
                  // It's a polygon
                  final polygonCubit = context.read<PolygonCubit>();
                  polygonCubit.addSecondaryPolygon(coords);
                  polygonCubit.addMainPolygons(item.type!);
                } else {
                  // It's a point
                  final coordinatesCubit = context.read<CoordinatesCubit>();
                  final first = coords[0];
                  coordinatesCubit.addPoint(
                    Position(first.longitude, first.latitude),
                  );
                }

                // Navigate to map — center on first coordinate
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapScreenWithAppBar(
                      child: MapScreen(
                        longitude: coords[0].longitude,
                        latitude: coords[0].latitude,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    },
  );
}
