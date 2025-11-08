import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:map_app/core/helpers/extensions.dart';
import 'package:map_app/core/theming/colors.dart';
import 'package:map_app/features/admin_user_screen/widgets/header.dart';
import 'package:map_app/features/admin_user_screen/services/build_list.dart';
import 'package:map_app/features/admin_user_screen/services/delete_data.dart';

class UserInfoScreen extends StatefulWidget {
  final String userId;

  const UserInfoScreen({required this.userId});

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  String _selectedView = 'polygons';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userId),
        backgroundColor: ColorsManager.mainGreen,
        actions: [
          IconButton(
            onPressed: () async {
              // Affiche la boîte de dialogue de confirmation
              bool? shouldDelete = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Confirmation'),
                    content: Text(
                      'Are you sure ? This will delete all user Data ',
                    ),
                    actions: [
                      // Bouton Annuler
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel'),
                      ),
                      // Bouton Supprimer
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );

              // Si l'utilisateur a confirmé (true), on supprime
              if (shouldDelete == true) {
                await DeleteDataForUser(widget.userId);
                // Optionnel : afficher un message de succès
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Data successfully deleted !')),
                );
              }
            },
            icon: Icon(Icons.delete_forever_sharp),
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(), // 👈 This listens for real-time changes
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text("User not found"));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final userRole = userData['role'] as String? ?? 'normal';

          Query polygonQuery;
          Query pointQuery;

          polygonQuery = FirebaseFirestore.instance
              .collection('polygones')
              .where('userId', isEqualTo: widget.userId);
          pointQuery = FirebaseFirestore.instance
              .collection('points')
              .where('userId', isEqualTo: widget.userId);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 👉 Header
                  UserHeader2(
                    name: userData['email'] ?? 'Unknown',
                    role: userData['role'] ?? 'Unknown Role',
                    onPressed: () async {
                      final bool isConnected = await InternetConnectionChecker
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
                      final newRole = await showModalBottomSheet<String>(
                        context: context,
                        builder: (context) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Select New Role',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ...['normal', 'contributor', 'admin'].map((
                                  role,
                                ) {
                                  return ListTile(
                                    title: Text(role.toUpperCase()),
                                    leading: Icon(
                                      role == 'admin'
                                          ? Icons.admin_panel_settings
                                          : role == 'contributor'
                                          ? Icons.person_add
                                          : Icons.person,
                                      color: role == 'admin'
                                          ? Colors.red
                                          : role == 'contributor'
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                    onTap: () async {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(widget.userId)
                                          .update({'role': role});
                                      context.pop();
                                    },
                                  );
                                }).toList(),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context), // Cancel
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: ColorsManager.mainGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );

                      if (newRole != null && newRole != userRole) {
                        // ✅ Handle role update here
                        // Example: call context.read<UserCubit>().updateRole(newRole);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Role updated to $newRole')),
                        );
                      }
                    },
                  ),
                  SizedBox(height: 10.h),

                  // 👉 Toggle Button
                  Center(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'polygons',
                          label: Text('Polygons'),
                        ),
                        ButtonSegment<String>(
                          value: 'points',
                          label: Text('Points'),
                        ),
                      ],
                      selected: {_selectedView},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _selectedView = newSelection.first;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // 👉 Show Selected List
                  Expanded(
                    child: _selectedView == 'polygons'
                        ? buildListSection(
                            title: "polygones",
                            query: polygonQuery,
                            emptyText: "No polygons yet",
                          )
                        : _selectedView == 'points'
                        ? buildListSection(
                            title: "points",
                            query: pointQuery,
                            emptyText: "No points yet",
                          )
                        : Container(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
