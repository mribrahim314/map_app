import 'package:flutter/material.dart';
import 'package:map_app/core/theming/colors.dart';

class UserHeader extends StatelessWidget {
  const UserHeader({super.key, required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    // Capitalize first letter of name
    String capitalizedName = name.isNotEmpty
        ? name[0].toUpperCase() + name.substring(1)
        : '';

    return Container(
      width: 180,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey[200],
            child: const Icon(
              Icons.person,
              size: 40,
              color: ColorsManager
                  .mainGreen, // 👈 Ensure ColorsManager is imported
            ),
          ),
          const SizedBox(height: 12),
          Text(
            capitalizedName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (role != "normal")
            Text(
              'Role: ${role.toUpperCase()}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
        ],
      ),
    );
  }
}
