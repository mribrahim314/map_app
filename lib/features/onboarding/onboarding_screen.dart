import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:map_app/features/onboarding/widgets/get_started_button.dart';
import 'package:map_app/features/onboarding/widgets/onboarding_stack.dart';
import 'package:map_app/features/onboarding/widgets/text_and_logo.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Container(
            color: Color(0xFFfbfcfc),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                children: [
                  const TextAndLogo(),
                  // SizedBox(height: 10.h),
                  const OnboardingStack(),
                  SizedBox(height: 60.h),
                          
                  GetStartedButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
