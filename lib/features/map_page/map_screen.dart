import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:map_app/core/cubit/draw_cubit.dart';
import 'package:map_app/core/cubit/coordinates_cubit.dart';
import 'package:map_app/core/cubit/polygone_cubit.dart';
import 'package:map_app/features/main_screen/customized_floating_action_button.dart';

import 'package:maplibre/maplibre.dart';

class MapScreen extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  MapScreen({super.key, this.latitude, this.longitude});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // final String styleUrl =
  //     'https://api.maptiler.com/maps/winter/style.json?key=BfK03RiSlmi1DtFSAqPr';
  final String apiKey = 'BfK03RiSlmi1DtFSAqPr';

  final String sourceId = "lebanon_source";

  final String layerId = "lebanon_layer";

  late MapController _mapController;
  bool isinitialized = false;
  String _getStyleUrl(String viewMode) {
    return 'https://api.maptiler.com/maps/$viewMode/style.json?key=$apiKey';
  }

  @override
  Widget build(BuildContext context) {
    final drawcubit = context.watch<DrawModeCubit>();
    final coordinatescubit = context.read<CoordinatesCubit>();
    final polygonCubit2 = context.read<PolygonCubit>();

    return Scaffold(
      floatingActionButton: (isinitialized && widget.latitude == null)
          ? CustomizedFloatingActionButton(mapLibreController: _mapController)
          : null,
      body: BlocBuilder<PolygonCubit, PolygonState>(
        builder: (context, polygons2) {
          return BlocBuilder<CoordinatesCubit, List<Position>>(
            builder: (context, points) {
              return MapLibreMap(
                children: [MapCompass(alignment: Alignment(1, -0.6.h))],

                onMapCreated: (MapController controller) async {
                  _mapController = controller;
                  setState(() {
                    isinitialized = true;
                  });
                  // await _mapController.enableLocation();

                  if (widget.latitude != null && widget.longitude != null) {
                    // Coordinates are provided, animate the map to that location
                    await _mapController.animateCamera(
                      center: Position(widget.longitude!, widget.latitude!),
                      zoom: 17,
                    );
                  }

                  await _mapController.fitBounds(
                    bounds: LngLatBounds(
                      latitudeNorth: 34.7,
                      latitudeSouth: 33.0,
                      longitudeEast: 36.5,
                      longitudeWest: 35,
                    ),
                  );
                },

                onEvent: (MapEvent event) async {
                  switch (event) {
                    case MapEventClick():
                      final isDrawEnabled = context.read<DrawModeCubit>().state;
                      if (isDrawEnabled != 0) {
                        if (isDrawEnabled == 1) {
                          context.read<CoordinatesCubit>().clear();
                          context.read<CoordinatesCubit>().addPoint(
                            event.point,
                          );

                          ///////////////////////////////////
                          final coord = context
                              .read<CoordinatesCubit>()
                              .state[0];
                          String lngWithDirection =
                              '${coord.lng}° ${coord.lng >= 0 ? 'E' : 'W'}';

                          String latWithDirection =
                              '${coord.lat}° ${coord.lat >= 0 ? 'N' : 'S'}';

                          print(
                            lngWithDirection,
                          ); // e.g. "33.90378782751691° E"
                          print(
                            latWithDirection,
                          ); // e.g. "35.55978665340092° N"
                          ///////////////////////////////////
                          return;
                        }
                        if (points.length > 3) {
                          context
                              .read<CoordinatesCubit>()
                              .removeLastCondition();
                        }
                        context.read<CoordinatesCubit>().addPoint(event.point);
                        // polygonPoints.add(event.point);
                        // print(polygonPoints);

                        // context.read<PolygonCubit>().removeLastCondition();
                        context.read<CoordinatesCubit>().sortClockwise();
                      }
                    default:
                      break;
                  }

                  // print(event.toString());
                },
                //   onMapCreated: (controller) async{
                //     _mapController = controller;
                //       final Position center = await _mapController.;
                // // final double zoom = await _mapController.getZoom();

                // // print("Map Center: Lat: ${center.latitude}, Lng: ${center.longitude}");
                // // print("Zoom Level: $zoom");
                //   },
                options: MapOptions(
                  maxZoom: 20,
                  minZoom: 6,
                  maxBounds: LngLatBounds(
                    latitudeNorth: 34.7,
                    latitudeSouth: 33.0,
                    longitudeEast: 36.5,
                    longitudeWest: 35.0,
                  ),

                  // initZoom: 8.5,
                  // initCenter:
                  //     (widget.latitude == null && widget.longitude == null)
                  //     ? Position(35.8623, 33.8547)
                  //     : Position(
                  //         widget.longitude as num,
                  //         widget.longitude as num,
                  //       ), // Centered on Lebanon
                  initCenter: Position(35.8623, 33.8547),
                  initStyle:
                      'https://api.maptiler.com/maps/hybrid/style.json?key=$apiKey',
                ),
                layers: [
                  PolygonLayer(
                    polygons:
                        // (drawcubit.state != 0 || coordinatescubit.isEmpty())
                        drawcubit.state == 0 ? polygons2.mainPolygons : [],

                    color: Color(0x80FF0000),
                    outlineColor: Colors.red,
                  ),
                  PolygonLayer(
                    polygons: polygons2.secondaryPolygons,
                    color: const Color.fromARGB(200, 255, 235, 59),
                    outlineColor: Colors.orange,
                  ),
                  CircleLayer(
                    points: points
                        .map((position) => Point(coordinates: position))
                        .toList(),
                    color: Colors.blue,
                  ),
                  PolylineLayer(
                    polylines: [
                      if (drawcubit.state == 2 && points.length >= 2)
                        //drawcubic.state  == 2 means the user is in draw ploygone mode
                        //this is done to avoid creating polylines when i want to show a point
                        LineString.fromPoints(
                          points: points
                              .map((position) => Point(coordinates: position))
                              .toList(),
                        ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
