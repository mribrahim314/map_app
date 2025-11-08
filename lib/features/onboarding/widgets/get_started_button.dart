import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:map_app/core/helpers/extensions.dart';
import 'package:map_app/core/routing/routes.dart';
import 'package:map_app/core/theming/colors.dart';

class GetStartedButton extends StatelessWidget {
  const GetStartedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.pushNamed(Routes.logInScreen);
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(350.w, 55.w),
        backgroundColor: ColorsManager.mainGreen,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
      ),
      child: Text(
        'Get Started',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
