// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:map_app/core/cubit/draw_cubit.dart';
// import 'package:map_app/core/cubit/polygone_gl.dart';
// import 'package:maplibre_gl/maplibre_gl.dart';
// import 'package:mapbox_maps_flutter_draw/mapbox_maps_flutter_draw.dart';

// class MapScreenGl extends StatelessWidget {
//   MapScreenGl({super.key});

//   final String styleUrl =
//       'https://api.maptiler.com/maps/hybrid/style.json?key=BfK03RiSlmi1DtFSAqPr';

//   late MapLibreMapController _mapController;
//   late MapboxDrawController _mapboxDrawController;

//   Future<Uint8List> _loadMarkerBytes() async {
//     final bytes = await rootBundle.load('marker.png');
//     return bytes.buffer.asUint8List();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: BlocListener<PolygonCubitGl, List<LatLng>>(
//         listener: (context, points) async {
//           if (_mapController == null || points.isEmpty) return;

//           final latlngs = List<LatLng>.from(points);

//           print("latlngs list : ${latlngs}");
//           // Close the polygon
//           // if (latlngs.length >= 3 && latlngs.first != latlngs.last) {
//           //   latlngs.add(latlngs.first);
//           // }

//           // Optional: Remove previous fills
//           // await _mapController.clearSources();
//           // final slatlngs = [
//           //   [
//           //     LatLng(33.846094316432584, 35.48800218490749),
//           //     LatLng(33.86691410450345, 35.51425890102993),
//           //     LatLng(33.880416117799655, 35.498335473188575),
//           //     LatLng(33.88210371927053, 35.48376723069427),
//           //   ],
//           // ];
//           _mapController.clearFills();
//           try {
//             await _mapController.addFill(
//               FillOptions(
//                 geometry: [latlngs],

//                 fillColor: "#FF0000",
//                 fillOpacity: 0.5,
//                 fillOutlineColor: "#FF0000",
//                 // fillPattern:
//               ),
//             );
//           } catch (e) {
//             print(e);
//           }
//         },
        
//         child: BlocBuilder<PolygonCubitGl, List<LatLng>>(
//           builder: (context, points) {
//             return MapLibreMap(
//               styleString: styleUrl,
//               initialCameraPosition: CameraPosition(
//                 target: LatLng(33.8547, 35.8623), // Default to Beirut, Lebanon
//                 zoom: 7.5,
//               ),
//               minMaxZoomPreference: const MinMaxZoomPreference(0, 20),

//               onMapCreated: (controller) async {
//                 _mapController = controller;
                
//                 // Fit the camera to show all of Lebanon
//                 // await _mapController.(
//                 //   LatLngBounds(
//                 //     southwest: LatLng(32.5, 34.8),  // Southern/Western Lebanon
//                 //     northeast: LatLng(34.7, 36.6),  // Northern/Eastern Lebanon
//                 //   ),
//                 //   padding: 50,
//                 // );
//                 final centerOfLebanon = LatLng(33.8547, 35.8623); // Beirut
//                 await _mapController.moveCamera(
//                   CameraUpdate.newLatLngZoom(centerOfLebanon, 7.5),
//                 );
//               },

//               onMapClick: (screenPoint, latlng) async {
//                 try {
//                   final isDrawEnabled = context.read<DrawModeCubit>().state;
//                   final polygonCubit = context.read<PolygonCubitGl>();

//                   if (isDrawEnabled) {
//                     polygonCubit.addPoint(latlng);
//                     // polygonCubit.sortClockwise();
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text(
//                           'Point added: (${latlng.latitude}, ${latlng.longitude})',
//                         ),
//                         duration: Duration(seconds: 1),
//                       ),
//                     );
//                   }
//                 } catch (e) {
//                   print(e);
//                 }
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
