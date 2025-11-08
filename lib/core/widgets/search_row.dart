import 'package:flutter/material.dart';
import 'package:map_app/core/theming/colors.dart';
import 'package:map_app/core/widgets/customized_text_field.dart';

class SearchRow extends StatelessWidget {
  final TextEditingController userNameController;
  final VoidCallback onPressed;

  SearchRow({super.key, required this.userNameController, required this.onPressed});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 8,
          child: CustomizedTextField(controller: userNameController),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 22, left: 8, right: 8),
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.mainGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  // shadowColor: Colors.blue.withOpacity(0.3),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
