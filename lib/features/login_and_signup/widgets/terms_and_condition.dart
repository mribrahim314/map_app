import 'package:flutter/material.dart';
import 'package:map_app/core/theming/styles.dart';

class TermsAndConditionsText extends StatelessWidget {
  const TermsAndConditionsText({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.center,
      child: RichText(
        textAlign: TextAlign.center,

        text: TextSpan(
          style: TextStyle(height: 1.8),
          children: [
            TextSpan(
              text: 'By logging, you agree to our \n',
              style: TextStyles.font14Black400Weight,
            ),
            TextSpan(
              text: ' Terms & Conditions',
              style: TextStyles.font14Black400Weight,
              
            ),
            TextSpan(
              text: ' and',
              style: TextStyles.font14Black400Weight,
              
            ),
            TextSpan(
              text: ' Privacy Policy',
              style: TextStyles.font14Black400Weight,
              
            ),
          ],
        ),
      ),
    );
  }
}
