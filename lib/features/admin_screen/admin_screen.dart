import 'package:flutter/material.dart';
import 'package:map_app/core/helpers/extensions.dart';
import 'package:map_app/core/routing/routes.dart';
import 'package:map_app/core/theming/colors.dart';
import 'package:map_app/features/admin_user_screen/screens/admin_user_info_screen.dart';
import 'package:map_app/core/repositories/user_repository.dart';
import 'package:map_app/core/models/user_model.dart';
import 'user_card.dart';

class AdminScreen extends StatefulWidget {
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final UserRepository _userRepo = UserRepository();
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = _userRepo.getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel", style: TextStyle(color: Colors.white)),
        backgroundColor: ColorsManager.mainGreen,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () {
              context.pushNamed(Routes.exportScreen);
            },
            icon: Icon(Icons.ios_share_rounded, color: Colors.white),
            tooltip: 'Export Data',
          ),
        ],
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error loading users: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUsers,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No users found'),
                ],
              ),
            );
          }

          final users = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _loadUsers();
            },
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                // Convert UserModel to Map for UserCard compatibility
                final userData = {
                  'name': user.email,
                  'role': user.role,
                  'requestSent': user.contributionRequestSent,
                  'contributionCount': user.contributionCount,
                };

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UserInfoScreen(
                          userId: user.id,
                        ),
                      ),
                    ).then((_) => _loadUsers()); // Refresh after returning
                  },
                  child: UserCard(userData: userData),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
