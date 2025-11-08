import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:map_app/core/helpers/extensions.dart';
import 'package:map_app/core/routing/routes.dart';
import 'package:map_app/core/theming/colors.dart';
import 'package:map_app/features/admin_user_screen/screens/admin_user_info_screen.dart';
import 'user_card.dart';

class AdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel", style: TextStyle(color: Colors.white)),
        backgroundColor: ColorsManager.mainGreen,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              context.pushNamed(Routes.exportScreen);
            },
            icon: Icon(Icons.ios_share_rounded, color: Colors.white),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserInfoScreen(
                        userId: users[index].id,
                      ), // Pass userId here
                    ),
                  );
                  print(users[index].id);
                },
                child: UserCard(userData: user),
              );
            },
          );
        },
      ),
    );
  }
}
