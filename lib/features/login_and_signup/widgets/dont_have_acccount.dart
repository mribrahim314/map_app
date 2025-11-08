import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:map_app/core/helpers/extensions.dart';
import 'package:map_app/core/routing/routes.dart';
import 'package:map_app/core/theming/styles.dart';

class DontHaveAccountText extends StatelessWidget {
  const DontHaveAccountText({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.center,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Don\'t have an account?',
              style: TextStyles.font14Black400Weight,
            ),
            TextSpan(
              text: ' Sign Up',
              style: TextStyles.font14green200Weight,
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO: Replace with your navigation logic
                  context.pushNamed(Routes.signUpScreen);
                },
            ),
          ],
        ),
      ),
    );
  }
}
