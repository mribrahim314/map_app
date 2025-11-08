import 'package:flutter/material.dart';
import 'package:map_app/core/theming/styles.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.center,
      child: Text('Forgot Password?', style: TextStyles.font14green200Weight),
    );
  }
}
