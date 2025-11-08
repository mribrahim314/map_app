// // polygon_point_card.dart
// import 'dart:ffi';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:map_app/core/cubit/user_role_cubit.dart';
// import 'package:map_app/core/theming/colors.dart';
// import 'package:map_app/features/admin_user_screen/screens/edit_screen.dart';
// import 'package:provider/provider.dart';

// class PolygonPointCard extends StatelessWidget {
//   final Map<String, dynamic> data;
//   final VoidCallback onViewMap;
//   final VoidCallback onAdopt;
//   final VoidCallback onDelete;
//   final String adoptText;
//   final Bool noNet;
//   final polygonId;

//   const PolygonPointCard({
//     required this.data,
//     required this.onViewMap,
//     required this.onAdopt,
//     required this.onDelete,
//     required this.adoptText,
//     required this.polygonId,
//     required this.noNet,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final currentUserRole = context.read<UserRoleCubit>().role;
//     final showAdoptButton =
//         currentUserRole == 'admin' || currentUserRole == 'contributor';
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 8.0),
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Card_Header(data: data, polygonId: polygonId),
//             SizedBox(height: 4),
//             Text(
//               data['Message'] ?? '',
//               style: TextStyle(color: Colors.grey[600]),
//             ),

//             // 👉 District & Gouvernante
//             // if (data.containsKey('District') || data.containsKey('Gouvernante'))
//             if (data['Gouvernante'] != null) Card_Location(data: data),

//             // 👉 Image URL (if exists)
//             if (data['imageURL'] != null && data['imageURL'] != 'null')
//               CardImage(data: data),

//             // 👉 Buttons
//             SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 CardButton(
//                   onPressed: onViewMap,
//                   buttonColor: ColorsManager.mainGreen,
//                   label: 'View',
//                   icon: const Icon(Icons.map, size: 16),
//                 ),
//                 if (showAdoptButton)
//                   CardButton(
//                     onPressed: onAdopt,
//                     buttonColor: Colors.blue,
//                     label: adoptText,
//                     icon: const Icon(Icons.check_circle, size: 16),
//                   ),
//                 // const SizedBox(height: 8),
//                 CardButton(
//                   onPressed: onDelete,
//                   buttonColor: Colors.red,
//                   label: 'Delete',
//                   icon: const Icon(Icons.delete, size: 16),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CardImage extends StatelessWidget {
//   const CardImage({super.key, required this.data});

//   final Map<String, dynamic> data;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 100,
//       width: double.infinity,
//       child: GestureDetector(
//         onTap: () {
//           showDialog(
//             context: context,
//             builder: (BuildContext context) {
//               return Dialog(
//                 backgroundColor: Colors.transparent,
//                 insetPadding: EdgeInsets.zero,
//                 child: GestureDetector(
//                   onTap: () => Navigator.pop(context), // Tap to dismiss
//                   child: Hero(
//                     tag:
//                         data['imageURL'], // Optional: for smooth transition if you use Hero elsewhere
//                     child: Material(
//                       color: Colors.transparent,
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Stack(
//                           children: [
//                             InteractiveViewer(
//                               child: Image.network(
//                                 data['imageURL'],
//                                 fit: BoxFit.contain,
//                                 loadingBuilder: (context, child, progress) {
//                                   if (progress == null) return child;
//                                   return const Center(
//                                     child: CircularProgressIndicator(),
//                                   );
//                                 },
//                               ),
//                             ),
//                             Positioned(
//                               top: 40,
//                               left: 20,
//                               child: IconButton(
//                                 icon: const Icon(
//                                   Icons.close,
//                                   color: Colors.white,
//                                 ),
//                                 onPressed: () => Navigator.pop(context),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//         child: Container(
//           width: double.infinity,
//           height: double.infinity,
//           child: Image.network(
//             data['imageURL'],
//             fit: BoxFit.cover,
//             loadingBuilder: (context, child, progress) {
//               if (progress == null) return child;
//               return const Center(child: CircularProgressIndicator());
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

// class CardButton extends StatelessWidget {
//   const CardButton({
//     super.key,
//     required this.onPressed,
//     required this.buttonColor,
//     required this.label,
//     required this.icon,
//   });

//   final VoidCallback onPressed;
//   final Color buttonColor; // required
//   final String label; // required
//   final Icon icon; // optional, defaults to a map icon

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 1),
//       child: ElevatedButton.icon(
//         onPressed: onPressed,
//         icon: icon,
//         label: Text(label, style: TextStyle(color: Colors.white)),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: buttonColor,
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         ),
//       ),
//     );
//   }
// }

// class Card_Location extends StatelessWidget {
//   const Card_Location({super.key, required this.data});

//   final Map<String, dynamic> data;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Location:',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.grey[700],
//           ),
//         ),
//         Text(
//           '${data['District'] ?? ''}, ${data['Gouvernante'] ?? ''}',
//           style: TextStyle(color: Colors.black),
//         ),
//       ],
//     );
//   }
// }

// class Card_Header extends StatelessWidget {
//   const Card_Header({super.key, required this.data, required this.polygonId});

//   final Map<String, dynamic> data;
//   final dynamic polygonId;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               '${data['Type'] ?? 'Unknown'}',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: ColorsManager.mainGreen,
//               ),
//             ),

//             IconButton(
//               onPressed: () {
//                 final docRef = FirebaseFirestore.instance
//                     .collection('polygones')
//                     .doc();
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>
//                         EditScreen(polygonId: polygonId, data: data),
//                   ),
//                 );
//               },
//               icon: Icon(Icons.edit),
//             ),
//           ],
//         ),
//         Text(
//           '${data['Date'] ?? ''}',
//           style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//         ),
//       ],
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:map_app/core/cubit/user_role_cubit.dart';
import 'package:map_app/core/theming/colors.dart';
import 'package:map_app/features/admin_user_screen/screens/edit_screen.dart';
import 'package:provider/provider.dart';

class PolygonPointCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onViewMap;
  final VoidCallback onAdopt;
  final VoidCallback onDelete;
  final String adoptText;
  final bool noNet; // ✅ proper type
  final dynamic polygonId;

  const PolygonPointCard({
    super.key,
    required this.data,
    required this.onViewMap,
    required this.onAdopt,
    required this.onDelete,
    required this.adoptText,
    required this.polygonId,
    required this.noNet,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserRole = context.read<UserRoleCubit>().role;
    final showAdoptButton =
        currentUserRole == 'admin' || currentUserRole == 'contributor';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardHeader(data: data, polygonId: polygonId, noNet: noNet),
            const SizedBox(height: 4),
            Text(
              data['Message'] ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),

            if (data['Gouvernante'] != null) CardLocation(data: data),

            if (data['imageURL'] != null && data['imageURL'] != 'null')
              CardImage(data: data),

            const SizedBox(height: 16),

            // ✅ Buttons logic
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!noNet) ...[
                  // Online: show all action buttons
                  CardButton(
                    onPressed: onViewMap,
                    buttonColor: ColorsManager.mainGreen,
                    label: 'View',
                    icon: const Icon(Icons.map, size: 16),
                  ),
                  if (showAdoptButton)
                    CardButton(
                      onPressed: onAdopt,
                      buttonColor: Colors.blue,
                      label: adoptText,
                      icon: const Icon(Icons.check_circle, size: 16),
                    ),
                ],

                // Always show delete button (even offline)
                CardButton(
                  onPressed: onDelete,
                  buttonColor: Colors.red,
                  label: 'Delete',
                  icon: const Icon(Icons.delete, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CardImage extends StatelessWidget {
  const CardImage({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: EdgeInsets.zero,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Hero(
                    tag: data['imageURL'],
                    child: Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              child: Image.network(
                                data['imageURL'],
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 40,
                              left: 20,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        child: Image.network(
          data['imageURL'],
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class CardButton extends StatelessWidget {
  const CardButton({
    super.key,
    required this.onPressed,
    required this.buttonColor,
    required this.label,
    required this.icon,
  });

  final VoidCallback onPressed;
  final Color buttonColor;
  final String label;
  final Icon icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}

class CardLocation extends StatelessWidget {
  const CardLocation({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        Text(
          '${data['District'] ?? ''}, ${data['Gouvernante'] ?? ''}',
          style: const TextStyle(color: Colors.black),
        ),
      ],
    );
  }
}

class CardHeader extends StatelessWidget {
  const CardHeader({
    super.key,
    required this.data,
    required this.polygonId,
    required this.noNet,
  });

  final Map<String, dynamic> data;
  final dynamic polygonId;
  final bool noNet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${data['Type'] ?? 'Unknown'}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorsManager.mainGreen,
              ),
            ),

            // ✅ Hide edit button when offline
            if (!noNet)
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditScreen(polygonId: polygonId, data: data),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
              ),
          ],
        ),
        Text(
          '${data['Date'] ?? ''}',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
