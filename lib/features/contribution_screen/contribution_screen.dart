import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:map_app/core/theming/colors.dart';
import 'package:map_app/features/admin_user_screen/services/build_list.dart';
import 'package:map_app/features/admin_user_screen/services/build_list_offline.dart';

class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({super.key});

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen> {
  String _selectedView = 'polygons';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.person_off, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "You're not signed in",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Build queries for current user
    final polygonQuery = FirebaseFirestore.instance
        .collection('polygones')
        .where('userId', isEqualTo: user.uid);
    // .orderBy('TimeStamp', descending: true);

    final pointQuery = FirebaseFirestore.instance
        .collection('points')
        .where('userId', isEqualTo: user.uid);
    // .orderBy('TimeStamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'My Contributions',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: ColorsManager.mainGreen,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle between Polygons & Points
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
                    ButtonSegment<String>(
                      value: 'Offline',
                      label: Text('Offline'),
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

              // Show the list
              Expanded(
                child: _selectedView == 'polygons'
                    ? buildListSection(
                        title: "polygones",
                        query: polygonQuery,
                        emptyText: "You haven't added any polygons yet.",
                      )
                    : _selectedView == 'points'
                    ? buildListSection(
                        title: "points",
                        query: pointQuery,
                        emptyText: "You haven't added any points yet.",
                      )
                    : buildOfflineUnifiedList(
                        context: context,
                        emptyText: "No offline Data",
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
