import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:map_app/core/theming/styles.dart';

class OnboardingStack extends StatelessWidget {
  const OnboardingStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          child: SvgPicture.asset(
            'assets/arabic_logo.svg',
            height: 270.w,
            width: 270.w,
            fit: BoxFit.contain,
          ),
          // child: Image.asset('assets/arabic_logo.jpeg', scale: 0.5),
        ),
        Text(
          "\n Explore detailed map of \n trees species across Lebanon",
          style: TextStyles.font24Green700Weight,
          textAlign: TextAlign.center,
        ),
        Text(
          textAlign: TextAlign.center,
          "Be a part of the community \n Tell us where green spaces are in your area.",
        ),
      ],
    );
  }
}
