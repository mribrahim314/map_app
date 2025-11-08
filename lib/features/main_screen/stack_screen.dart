import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:map_app/core/cubit/draw_cubit.dart';
import 'package:map_app/core/cubit/coordinates_cubit.dart';
import 'package:map_app/core/helpers/extensions.dart';
import 'package:map_app/core/helpers/spacing.dart';
import 'package:map_app/core/routing/routes.dart';
import 'package:map_app/core/theming/colors.dart';

import 'package:map_app/features/main_screen/category_selector.dart';
import 'package:map_app/features/map_page/map_screen.dart';
import 'package:maplibre/maplibre.dart';

class StackScreen extends StatelessWidget {
  const StackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final polygonCubit = context.read<CoordinatesCubit>();
    return Stack(
      children: [
        MapScreen(),
        // MapScreenGl(),
        // DragSheet(),
        // DragSheetWrapper(),
        BlocBuilder<DrawModeCubit, int>(
          builder: (context, isdraw) {
            return (isdraw != 0)
                ? Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: PreferredSize(
                      preferredSize: Size.fromHeight(56),
                      child: AppBar(
                        actions: [
                          BlocBuilder<CoordinatesCubit, List<Position>>(
                            builder: (context, points) {
                              final cubit = context.read<CoordinatesCubit>();
                              final isEmpty = cubit.isEmpty();
                              
                              return GestureDetector(
                                onTap: () {
                                  if ((isdraw == 1 && points.length == 1) ||
                                      !isEmpty) {
                                    context.pushNamed(Routes.drawScreen);
                                  }
                                },
                                // (isdraw == 1)? isEmpty
                                //     ? null
                                //     : () =>
                                //           context.pushNamed(Routes.drawScreen),
                                child: Icon(
                                  Icons.check,
                                  color:
                                      ((isdraw == 1 && points.length == 1) ||
                                          !isEmpty)
                                      ? Colors.black
                                      : Color.fromARGB(
                                          255,
                                          84,
                                          78,
                                          78,
                                        ).withOpacity(0.5),
                                  // color: isEmpty
                                  //     ? const Color.fromARGB(
                                  //         255,
                                  //         84,
                                  //         78,
                                  //         78,
                                  //       ).withOpacity(0.5)
                                  //     : Colors.black,
                                ),
                              );
                            },
                          ),
                          HorizontalSpacing(10),
                        ],

                        automaticallyImplyLeading: false,
                        leading: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            context.read<DrawModeCubit>().disable();
                            polygonCubit.clear();
                          },
                        ),
                        centerTitle: true,
                        title: Text(
                          isdraw == 2 ? 'Draw a polygone' : 'Draw a point ',
                        ),
                        backgroundColor: ColorsManager.mainGreen,
                      ),
                    ),
                  )
                // : SizedBox.shrink();
                : SafeArea(child: CategorySelector());
          },
        ),
       
      ],
    );
  }
}
