// ============================================================================
// CLEANED BY CLAUDE - Removed Firebase/Firestore dependencies
// Rewritten to use PostgreSQL repositories
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:map_app/core/helpers/extensions.dart';
import 'package:map_app/core/theming/colors.dart';
import 'package:map_app/features/admin_user_screen/widgets/header.dart';
import 'package:map_app/features/admin_user_screen/services/build_list.dart';
import 'package:map_app/features/admin_user_screen/services/delete_data.dart';
import 'package:map_app/core/repositories/user_repository.dart';
import 'package:map_app/core/repositories/polygon_repository.dart';
import 'package:map_app/core/repositories/point_repository.dart';

class UserInfoScreen extends StatefulWidget {
  final String userId;

  const UserInfoScreen({required this.userId});

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  String _selectedView = 'polygons';
  final UserRepository _userRepo = UserRepository();
  final PolygonRepository _polygonRepo = PolygonRepository();
  final PointRepository _pointRepo = PointRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userId),
        backgroundColor: ColorsManager.mainGreen,
        actions: [
          IconButton(
            onPressed: () async {
              bool? shouldDelete = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Confirmation'),
                    content: Text(
                      'Are you sure? This will delete all user data',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel'),
                      ),
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

              if (shouldDelete == true) {
                await DeleteDataForUser(widget.userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Data successfully deleted!')),
                );
                if (mounted) {
                  setState(() {}); // Refresh the UI
                }
              }
            },
            icon: Icon(Icons.delete_forever_sharp),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _userRepo.getUserById(widget.userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(child: Text("User not found"));
          }

          final user = userSnapshot.data!;
          final userRole = user.role;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  UserHeader2(
                    name: user.email,
                    role: user.role,
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
                                      try {
                                        await _userRepo.updateUserRole(
                                          widget.userId,
                                          role,
                                        );
                                        Navigator.pop(context, role);
                                      } catch (e) {
                                        print('Error updating role: $e');
                                        Navigator.pop(context);
                                      }
                                    },
                                  );
                                }).toList(),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Role updated to $newRole')),
                        );
                        setState(() {}); // Refresh the UI
                      }
                    },
                  ),
                  SizedBox(height: 10.h),

                  // Toggle Button
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

                  // Show Selected List
                  Expanded(
                    child: _selectedView == 'polygons'
                        ? buildListSection(
                            title: "polygones",
                            userId: widget.userId,
                            emptyText: "No polygons yet",
                          )
                        : buildListSection(
                            title: "points",
                            userId: widget.userId,
                            emptyText: "No points yet",
                          ),
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
