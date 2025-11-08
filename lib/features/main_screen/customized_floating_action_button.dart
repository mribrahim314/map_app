import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:map_app/core/cubit/coordinates_cubit.dart';
import 'package:map_app/core/cubit/draw_cubit.dart';
import 'package:map_app/core/cubit/polygone_cubit.dart';
import 'package:map_app/core/networking/location.dart';
import 'package:map_app/core/theming/colors.dart';
import 'package:maplibre/maplibre.dart';


class CustomizedFloatingActionButton extends StatefulWidget {
  const CustomizedFloatingActionButton({
    super.key,
    required this.mapLibreController,
  });
  final MapController mapLibreController;

  @override
  State<CustomizedFloatingActionButton> createState() =>
      _CustomizedFloatingActionButtonState();
}

class _CustomizedFloatingActionButtonState
    extends State<CustomizedFloatingActionButton> {
  bool isExpanded = false;
  void toggleMenu() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    PolygonCubit polygonCubit = context.read<PolygonCubit>();
    CoordinatesCubit coordinatesCubit = context.read<CoordinatesCubit>();

    return BlocBuilder<DrawModeCubit, int>(
      builder: (context, isdrawn) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            (isdrawn == 0)
                ? isExpanded
                      ? Container(
                          key: ValueKey('expanded'),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.amber,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                onPressed: () {
                                  context.read<DrawModeCubit>().enablePolygon();

                                  polygonCubit.clearAll();
                                  coordinatesCubit.clear();
                                  setState(() {
                                    isExpanded = false;
                                  });
                                },
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                tooltip: 'Draw Polygon',
                              ),
                              IconButton(
                                onPressed: () {
                                  context.read<DrawModeCubit>().enablePoint();

                                  polygonCubit.clearAll();
                                  coordinatesCubit.clear();

                                  setState(() {
                                    isExpanded = false;
                                  });
                                },
                                icon: Icon(
                                  Icons.add_location_alt_sharp,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                tooltip: 'Add Location',
                              ),
                              IconButton(
                                onPressed: toggleMenu,
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                tooltip: 'Close',
                              ),
                            ],
                          ),
                        )
                      : Container(
                          key: ValueKey('collapsed'),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.amber,
                          ),
                          child: IconButton(
                            onPressed: toggleMenu,
                            icon: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: 'Open Menu',
                          ),
                        )
                : SizedBox(height: 0, width: 0),

            SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'main',
              onPressed: () async {
                final controller = widget.mapLibreController;
                final position = await getCurrentLocation();

                await controller.enableLocation();
                controller.animateCamera(
                  center: Position(
                    position[0].toDouble(),
                    position[1].toDouble(),
                  ),
                  zoom: 17,
                );
                            },
              backgroundColor: ColorsManager.mainGreen,
              child: Icon(Icons.location_on, color: Colors.purple),
            ),
          ],
        );
      },
    );
  }
}
