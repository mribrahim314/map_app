import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TextAndLogo extends StatelessWidget {
  const TextAndLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.scale(scale: 0.5, child: SvgPicture.asset('assets/logo.svg')),
      ],
    );
  }
}
