import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:map_app/core/theming/colors.dart';
import 'package:map_app/core/theming/styles.dart';

class CustomizedTextField extends StatelessWidget {
  final TextEditingController controller;

  const CustomizedTextField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      cursorColor: ColorsManager.mainGreen,
      maxLength: 400,
      minLines: 1,
      maxLines: null, // Makes the TextField expand vertically
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hint: Text("Your message", style: TextStyles.font14LightGrayRegular),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: ColorsManager.lighterGray,
            width: 1.3,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: ColorsManager.lighterGray,
            width: 1.3,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        alignLabelWithHint: true, // Aligns label properly with multiline
        contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
      ),
    );
  }
}
