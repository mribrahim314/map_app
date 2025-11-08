// map_screen_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:map_app/core/cubit/coordinates_cubit.dart';
import 'package:map_app/core/cubit/draw_cubit.dart';
import 'package:map_app/core/cubit/polygone_cubit.dart';
import 'package:map_app/core/helpers/extensions.dart';
import 'package:maplibre/maplibre.dart';

class MapScreenWithAppBar extends StatelessWidget {
  final Widget child; // Your original map screen
  final bool showDownloadButton;

  MapScreenWithAppBar({required this.child, this.showDownloadButton = false});

  @override
  Widget build(BuildContext context) {
    PolygonCubit polygonCubit = context.read<PolygonCubit>();
    CoordinatesCubit coordinatesCubit = context.read<CoordinatesCubit>();
    DrawModeCubit drawModeCubit = context.read<DrawModeCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Map View'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            polygonCubit.clearAll();
            coordinatesCubit.clear();
            print(polygonCubit.state);
          },
        ),
        actions: showDownloadButton
            ? [
                IconButton(
                  icon: Icon(Icons.download),
                  onPressed: () async {
                    try {
                      final String apiKey = 'BfK03RiSlmi1DtFSAqPr';

                      final manager = await OfflineManager.createInstance();
                      final List<Position> coordinates = coordinatesCubit.state;

                      // Step 1: Compute bounding box
                      double minLat = coordinates.first.lat.toDouble();
                      double maxLat = coordinates.first.lat.toDouble();
                      double minLng = coordinates.first.lng.toDouble();
                      double maxLng = coordinates.first.lng.toDouble();

                      for (var pos in coordinates) {
                        if (pos.lat.toDouble() < minLat)
                          minLat = pos.lat.toDouble();
                        if (pos.lat.toDouble() > maxLat)
                          maxLat = pos.lat.toDouble();
                        if (pos.lng.toDouble() < minLng)
                          minLng = pos.lng.toDouble();
                        if (pos.lng.toDouble() > maxLng)
                          maxLng = pos.lng.toDouble();
                      }

                      final bounds = LngLatBounds(
                        latitudeNorth: maxLat,
                        latitudeSouth: minLat,
                        longitudeEast: maxLng,
                        longitudeWest: minLng,
                      );

                      final stream = manager.downloadRegion(
                        minZoom: 10,
                        maxZoom: 14,
                        // bounds: LngLatBounds(
                        //   latitudeNorth: 34.703,
                        //   latitudeSouth: 33.082,
                        //   longitudeEast: 36.611,
                        //   longitudeWest: 35.126,
                        // ),
                        bounds: bounds,
                        mapStyleUrl:
                            'https://api.maptiler.com/maps/hybrid/style.json?key=$apiKey',
                        pixelDensity: 1,
                      );
                      drawModeCubit.disable();
                      context.pop();

                      await for (final update in stream) {
                        if (update.downloadCompleted) {
                          print('Region downloaded: ${update.region}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Region downloaded!')),
                          );
                        } else {
                          final progressText =
                              '${update.loadedTiles} / ${update.totalTiles} '
                              '(${((update.progress ?? 0) * 100).toStringAsFixed(0)}%)';

                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text('Downloading map: $progressText'),
                                duration: const Duration(days: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Download failed: $e')),
                      );
                    }
                  },
                ),
              ]
            : [],
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: child,
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:map_app/core/cubit/coordinates_cubit.dart';
// import 'package:map_app/core/cubit/draw_cubit.dart';
// import 'package:map_app/core/cubit/polygone_cubit.dart';
// import 'package:maplibre/maplibre.dart';

// class MapScreenWithAppBar extends StatelessWidget {
//   final Widget child; // Your MapScreen
//   final bool showDownloadButton;

//   MapScreenWithAppBar({required this.child, this.showDownloadButton = false});

//   @override
//   Widget build(BuildContext context) {
//     final polygonCubit = context.read<PolygonCubit>();
//     final coordinatesCubit = context.read<CoordinatesCubit>();
//     final drawCubit = context.read<DrawModeCubit>();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Map View'),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pop(context);
//             polygonCubit.clearAll();
//             coordinatesCubit.clear();
//             drawCubit.disable();
//           },
//         ),
//       ),
//       floatingActionButton: showDownloadButton
//           ? FloatingActionButton(
//               child: Icon(Icons.download),
//               onPressed: () async {
//                 final polygons = polygonCubit.state.secondaryPolygons;
//                 if (polygons.isEmpty) {
//                   ScaffoldMessenger.of(
//                     context,
//                   ).showSnackBar(SnackBar(content: Text('No region selected')));
//                   return;
//                 }

//                 final polygonBounds = _computeBounds(polygons.first);

//                 final String apiKey = 'BfK03RiSlmi1DtFSAqPr';
//                 final manager = await OfflineManager.createInstance();
//                 final stream = manager.downloadRegion(
//                   minZoom: 10,
//                   maxZoom: 14,
//                   bounds: polygonBounds,
//                   mapStyleUrl:
//                       'https://api.maptiler.com/maps/hybrid/style.json?key=$apiKey',
//                   pixelDensity: 1,
//                 );

//                 await for (final update in stream) {
//                   if (update.downloadCompleted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Region downloaded!')),
//                     );
//                   } else {
//                     final progressText =
//                         '${update.loadedTiles} / ${update.totalTiles} '
//                         '(${((update.progress ?? 0) * 100).toStringAsFixed(0)}%)';

//                     ScaffoldMessenger.of(context)
//                       ..hideCurrentSnackBar()
//                       ..showSnackBar(
//                         SnackBar(
//                           content: Text('Downloading map: $progressText'),
//                           duration: Duration(days: 1),
//                         ),
//                       );
//                   }
//                 }
//               },
//             )
//           : null,
//       body: child,
//     );
//   }

//   // Helper to compute LngLatBounds from a polygon
//   LngLatBounds _computeBounds(List<GeoPoint> coords) {
//     double minLat = coords.first.latitude;
//     double maxLat = coords.first.latitude;
//     double minLng = coords.first.longitude;
//     double maxLng = coords.first.longitude;

//     for (var c in coords) {
//       if (c.latitude < minLat) minLat = c.latitude;
//       if (c.latitude > maxLat) maxLat = c.latitude;
//       if (c.longitude < minLng) minLng = c.longitude;
//       if (c.longitude > maxLng) maxLng = c.longitude;
//     }

//     return LngLatBounds(
//       latitudeNorth: maxLat,
//       latitudeSouth: minLat,
//       longitudeEast: maxLng,
//       longitudeWest: minLng,
//     );
//   }
// }
