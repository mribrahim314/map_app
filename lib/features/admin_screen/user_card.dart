// user_card.dart
import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserCard({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String email = userData['email'];
    String role = userData['role'];
    int contributionCount = userData['contributionCount'] ?? 0;
    bool contributionRequest = userData['contributionRequestSent'] ?? false;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(child: Text(role[0].toUpperCase())),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(email, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Role: $role", style: TextStyle(color: Colors.grey)),
                  Text(
                    "Contributions: $contributionCount",
                    style: TextStyle(color: Colors.green),
                  ),
                  if (contributionRequest)
                    Text(
                      "Wants to become a Contributor",
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
