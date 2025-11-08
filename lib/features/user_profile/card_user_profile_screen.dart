import 'package:flutter/material.dart';
import 'package:map_app/core/theming/colors.dart';

class CustomizedUserProfileScreenCard extends StatelessWidget {
  CustomizedUserProfileScreenCard({
    super.key,

    required this.primaryText,
    required this.icon,
    required this.ontapped,
    this.secondaryText = '',
  });

  final String primaryText;
  final IconData icon;
  final ontapped;
  String secondaryText;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontapped,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: ColorsManager.mainGreen, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryText,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
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
