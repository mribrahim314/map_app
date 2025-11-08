// ============================================================================
// CLEANED BY CLAUDE - Replaced Firebase StreamBuilder with PostgreSQL queries
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:map_app/core/cubit/coordinates_cubit.dart';
import 'package:map_app/core/cubit/polygone_cubit.dart';
import 'package:map_app/core/repositories/polygon_repository.dart';
import 'package:map_app/core/repositories/point_repository.dart';
import 'package:map_app/core/repositories/user_repository.dart';
import 'package:map_app/features/admin_user_screen/widgets/polygon_point_card.dart';
import 'package:map_app/features/admin_user_screen/screens/map_screen_with_appbar.dart';
import 'package:map_app/features/map_page/map_screen.dart';
import 'package:maplibre/maplibre.dart';

Widget buildListSection({
  required String title,
  required String userId,
  required String emptyText,
}) {
  return FutureBuilder(
    future: _fetchUserData(title, userId),
    builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(
          child: Text(
            'Error: ${snapshot.error}',
            style: TextStyle(color: Colors.red[600]),
          ),
        );
      }

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(
          child: Text(emptyText, style: TextStyle(color: Colors.grey[600])),
        );
      }

      final items = snapshot.data!;

      return SizedBox(
        height: 400,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final itemData = items[index];
            final docId = itemData['id'].toString();
            final adoptText = itemData['isAdopted'] ? " Retrieve" : "Adopt";
            return PolygonPointCard(
              noNet: false,
              polygonId: docId,
              onDelete: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Confirmation"),
                      content: Text("Are you sure to delete ?"),
                      actions: <Widget>[
                        TextButton(
                          child: Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () async {
                            final bool isConnected =
                                await InternetConnectionChecker
                                    .instance
                                    .hasConnection;

                            if (!isConnected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "No internet connection. Please check your network and try again.",
                                  ),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            Navigator.of(context).pop();

                            try {
                              // Delete from PostgreSQL
                              if (title == 'polygones') {
                                final polygonRepo = PolygonRepository();
                                await polygonRepo.deletePolygon(int.parse(docId));
                              } else {
                                final pointRepo = PointRepository();
                                await pointRepo.deletePoint(int.parse(docId));
                              }

                              // Decrement contribution count
                              final userRepo = UserRepository();
                              await userRepo.decrementContributionCount(
                                itemData['userId'],
                              );

                              print("Item deleted!");
                              // Trigger a rebuild by calling setState on the parent
                              // This is a workaround - ideally use a state management solution
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Item deleted successfully!"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error deleting item: $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              onEdit: () {},
              name: itemData['type'] ?? 'Unknown',
              showAdoptButton: false,
              onAdopt: () async {},
              adoptText: adoptText,
              data: itemData,
              onMapPressed: () async {
                if (title == 'polygones') {
                  final coordinates = itemData['coordinates'] as List;
                  final points = coordinates.map((coord) {
                    return coord;
                  }).toList();

                  context.read<PolygonCubit>().setCoord(points);
                  context.read<CoordinatesCubit>().setCoordinate(points);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreenWithAppBar(
                        polygonPoints: points,
                        markers: [],
                      ),
                    ),
                  );
                } else {
                  // For points
                  final coordinates = itemData['coordinates'] as List;
                  if (coordinates.isNotEmpty) {
                    final point = coordinates.first;
                    context.read<CoordinatesCubit>().setCoordinate([point]);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapScreenWithAppBar(
                          polygonPoints: [],
                          markers: [
                            Point(
                              coordinates: Position(
                                point['lng'],
                                point['lat'],
                              ),
                            ),
                          ], child: null,
                        ),
                      ),
                    );
                  }
                }
              }, onViewMap: () {  },
            );
          },
        ),
      );
    },
  );
}

Future<List<Map<String, dynamic>>> _fetchUserData(
  String collection,
  String userId,
) async {
  try {
    if (collection == 'polygones') {
      final polygonRepo = PolygonRepository();
      final polygons = await polygonRepo.getPolygonsByUserId(userId);
      return polygons.map((polygon) => polygon.toMap()).toList();
    } else {
      final pointRepo = PointRepository();
      final points = await pointRepo.getPointsByUserId(userId);
      return points.map((point) => point.toMap()).toList();
    }
  } catch (e) {
    print('Error fetching data: $e');
    return [];
  }
}
