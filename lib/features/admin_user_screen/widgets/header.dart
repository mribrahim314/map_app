import 'package:flutter/material.dart';
import 'package:map_app/core/theming/colors.dart';

class UserHeader2 extends StatelessWidget {
  final String name;
  final String role;
  final VoidCallback onPressed;

  const UserHeader2({
    super.key,
    required this.name,
    required this.role,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    String capitalizedName = name.isNotEmpty
        ? name[0].toUpperCase() + name.substring(1)
        : '';
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey[200],
            child: const Icon(
              Icons.person,
              size: 40,
              color: ColorsManager.mainGreen,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${role.toUpperCase()}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              ),

              
              IconButton(
                onPressed: onPressed,
                icon: const Icon(Icons.edit),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
