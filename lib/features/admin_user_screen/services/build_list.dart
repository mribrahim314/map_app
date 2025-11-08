import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:map_app/core/cubit/coordinates_cubit.dart';
import 'package:map_app/core/cubit/polygone_cubit.dart';
import 'package:map_app/features/admin_user_screen/widgets/polygon_point_card.dart';
import 'package:map_app/features/admin_user_screen/screens/map_screen_with_appbar.dart';
import 'package:map_app/features/map_page/map_screen.dart';
import 'package:maplibre/maplibre.dart';

Widget buildListSection({
  required String title,
  required Query query,
  required String emptyText,
}) {
  return StreamBuilder<QuerySnapshot>(
    stream: query.snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(
          child: Text(emptyText, style: TextStyle(color: Colors.grey[600])),
        );
      }

      final items = snapshot.data!.docs;

      return SizedBox(
        height: 400,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final itemData = items[index].data() as Map<String, dynamic>;
            final docId = items[index].id;
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
                            Navigator.of(context).pop(); // Fermer le dialogue
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

                            await FirebaseFirestore.instance
                                .collection(title)
                                .doc(docId)
                                .delete();

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(itemData['userId'])
                                .update({
                                  'contributionCount': FieldValue.increment(-1),
                                });
                            print("Élément supprimé !");
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              adoptText: adoptText,
              data: itemData,
              onAdopt: () async {
                final bool isConnected =
                    await InternetConnectionChecker.instance.hasConnection;

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
                final docRef = FirebaseFirestore.instance
                    .collection(title)
                    .doc(docId);
                print(docRef);
                final docSnapshot = await docRef.get();
                print(docSnapshot);

                if (docSnapshot.exists) {
                  print("hi");
                  final currentValue =
                      docSnapshot.data()?['isAdopted'] as bool? ?? false;

                  await docRef.update({'isAdopted': !currentValue});
                }
                print(adoptText);
              },
              /////////////////////////////////////////////////
              /////////////////////////////////////////////////
              /////////////////////////////////////////////////
              onViewMap: () {
                final List<GeoPoint> coordinates = List<GeoPoint>.from(
                  itemData['coordinates'],
                );
                if (title == "polygones") {
                  PolygonCubit polygonCubit = context.read<PolygonCubit>();
                  polygonCubit.addSecondaryPolygon(coordinates);
                  polygonCubit.addMainPolygons(itemData['Type']);
                  print(polygonCubit.state);
                } else {
                  CoordinatesCubit coordinatesCubit = context
                      .read<CoordinatesCubit>();
                  coordinatesCubit.addPoint(
                    Position(coordinates[0].longitude, coordinates[0].latitude),
                  );
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapScreenWithAppBar(
                      child: MapScreen(
                        longitude: coordinates[0].longitude,
                        latitude: coordinates[0].latitude,
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
