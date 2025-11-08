// // import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:map_app/core/cubit/draw_cubit.dart';
// // import 'package:map_app/core/helpers/extensions.dart';
// // import 'package:map_app/core/routing/routes.dart';

// // class DragSheet extends StatelessWidget {
// //   DragSheet({super.key});
// //   final DraggableScrollableController _controller =
// //       DraggableScrollableController();
// //   void func() {
// //     // _controller.animateTo(size, duration: duration, curve: curve)
// //   }
// //   @override
// //   Widget build(BuildContext context) {
// //     return DraggableScrollableSheet(
// //       minChildSize: 0.05, // 15% of screen height minimum
// //       maxChildSize: 0.3, // max 40% when dragged up
// //       initialChildSize: 0.3, // starts at 15%
// //       builder: (BuildContext context, ScrollController scrollController) {
// //         return Container(
// //           clipBehavior: Clip.hardEdge,
// //           decoration: BoxDecoration(
// //             color: Colors.black, // dark background like your screenshot
// //             borderRadius: const BorderRadius.only(
// //               topLeft: Radius.circular(25),
// //               topRight: Radius.circular(25),
// //             ),
// //           ),
// //           child: CustomScrollView(
// //             controller: scrollController,
// //             slivers: [
// //               // Drag handle
// //               SliverToBoxAdapter(
// //                 child: Center(
// //                   child: Container(
// //                     decoration: BoxDecoration(
// //                       color: Colors.grey[700],
// //                       borderRadius: BorderRadius.circular(10),
// //                     ),
// //                     height: 4,
// //                     width: 40,
// //                     margin: const EdgeInsets.symmetric(vertical: 10),
// //                   ),
// //                 ),
// //               ),
// //               // Top bar with "Contribute" and "View profile"
// //               SliverToBoxAdapter(
// //                 child: Padding(
// //                   padding: const EdgeInsets.symmetric(
// //                     horizontal: 16,
// //                     vertical: 8,
// //                   ),
// //                   child: Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       Text(
// //                         'Contribute',
// //                         style: TextStyle(
// //                           color: Colors.white,
// //                           fontSize: 20,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                       TextButton(
// //                         onPressed: () {
// //                           // Add your view profile logic here
// //                         },
// //                         child: Text(
// //                           'View profile',
// //                           style: TextStyle(color: Colors.tealAccent),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //               // Buttons row with icons and labels
// //               SliverToBoxAdapter(
// //                 child: Padding(
// //                   padding: const EdgeInsets.symmetric(
// //                     horizontal: 24,
// //                     vertical: 12,
// //                   ),
// //                   child: Row(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     children: [
// //                       // Add place button
// //                       GestureDetector(
// //                         onTap: () {
// //                            context.read<DrawModeCubit>().enable();
// //                         },
// //                         child: Column(
// //                           children: [
// //                             CircleAvatar(
// //                               radius: 24,
// //                               backgroundColor: Colors.teal,
// //                               child: IconButton(
// //                                 icon: Icon(Icons.add_location_alt),
// //                                 color: Colors.white,
// //                                 onPressed: () {
// //                                   // Add place action
// //                                 },
// //                               ),
// //                             ),
// //                             SizedBox(height: 6),
// //                             Text(
// //                               'Add place',
// //                               style: TextStyle(color: Colors.white),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                       SizedBox(width: 32),
// //                       // Update place button
// //                       Column(
// //                         children: [
// //                           CircleAvatar(
// //                             radius: 24,
// //                             backgroundColor: Colors.teal,
// //                             child: IconButton(
// //                               icon: Icon(Icons.share_outlined),
// //                               color: Colors.white,
// //                               onPressed: () {
// //                                 // Update place action
// //                               },
// //                             ),
// //                           ),
// //                           SizedBox(height: 6),
// //                           Text(
// //                             'Share location',
// //                             style: TextStyle(color: Colors.white),
// //                           ),
// //                         ],
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //               // Add more slivers here as needed or keep empty space
// //               SliverFillRemaining(hasScrollBody: false, child: Container()),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:map_app/core/cubit/draw_cubit.dart';
// import 'package:map_app/core/cubit/real_cubit.dart';

// class DragSheetWrapper extends StatefulWidget {
//   const DragSheetWrapper({Key? key}) : super(key: key);

//   @override
//   State<DragSheetWrapper> createState() => _DragSheetWrapperState();
// }

// class _DragSheetWrapperState extends State<DragSheetWrapper>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animController;
//   late Animation<double> _sizeAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _animController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 300),
//     );

//     _sizeAnimation = Tween<double>(begin: 0.3, end: 0.05).animate(
//       CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     _animController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<DrawModeCubit, bool>(
//       builder: (context, isDraw) {
//         if (isDraw) {
//           _animController.forward();
//         } else {
//           _animController.reverse();
//         }

//         return IgnorePointer(
//           ignoring: isDraw, // disable interactions when drawing mode active
//           child: AnimatedBuilder(
//             animation: _sizeAnimation,
//             builder: (context, child) {
//               return DraggableScrollableSheet(
//                 minChildSize: 0.05,
//                 maxChildSize: 0.3,
//                 initialChildSize: _sizeAnimation.value,
//                 builder: (BuildContext context, ScrollController scrollController) {
//                   return Container(
//                     clipBehavior: Clip.hardEdge,
//                     decoration: BoxDecoration(
//                       color: Colors.black,
//                       borderRadius: const BorderRadius.only(
//                         topLeft: Radius.circular(25),
//                         topRight: Radius.circular(25),
//                       ),
//                     ),
//                     child: CustomScrollView(
//                       controller: scrollController,
//                       slivers: [
//                         // Drag handle
//                         SliverToBoxAdapter(
//                           child: Center(
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[700],
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               height: 4,
//                               width: 40,
//                               margin: const EdgeInsets.symmetric(vertical: 10),
//                             ),
//                           ),
//                         ),
//                         // Top bar with "Contribute" and "View profile"
//                         SliverToBoxAdapter(
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 8,
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   'Contribute',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 TextButton(
//                                   onPressed: () {
//                                     // Add your view profile logic here
//                                   },
//                                   child: Text(
//                                     'View profile',
//                                     style: TextStyle(color: Colors.tealAccent),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         // Buttons row with icons and labels
//                         SliverToBoxAdapter(
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 24,
//                               vertical: 12,
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 // Add place button
//                                 GestureDetector(
//                                   onTap: () {
//                                     print(
//                                       'DrawModeCubit instance1: ${context.read<DrawModeCubit>().hashCode}',
//                                     );
//                                     print("state:");
//                                     context.read<DrawModeCubit>().enable();
//                                     print(context.read<DrawModeCubit>().state);
//                                     context.read<PolygonCubit2>().clear();
//                                   },
//                                   child: Column(
//                                     children: [
//                                       CircleAvatar(
//                                         radius: 24,
//                                         backgroundColor: Colors.teal,
//                                         child: IconButton(
//                                           icon: Icon(Icons.add_location_alt),
//                                           color: Colors.white,
//                                           onPressed: () {
//                                             // Add place action
//                                           },
//                                         ),
//                                       ),
//                                       SizedBox(height: 6),
//                                       Text(
//                                         'Add place',
//                                         style: TextStyle(color: Colors.white),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 SizedBox(width: 32),
//                                 // Update place button
//                                 Column(
//                                   children: [
//                                     CircleAvatar(
//                                       radius: 24,
//                                       backgroundColor: Colors.teal,
//                                       child: IconButton(
//                                         icon: Icon(Icons.share_outlined),
//                                         color: Colors.white,
//                                         onPressed: () {
//                                           // Update place action
//                                         },
//                                       ),
//                                     ),
//                                     SizedBox(height: 6),
//                                     Text(
//                                       'Share location',
//                                       style: TextStyle(color: Colors.white),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         SliverFillRemaining(
//                           hasScrollBody: false,
//                           child: Container(),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }
