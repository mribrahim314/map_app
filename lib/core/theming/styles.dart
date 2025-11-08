import 'package:flutter/material.dart';
import 'package:map_app/core/theming/colors.dart';

class TextStyles {
  static TextStyle font24Black700Weight = TextStyle(
    fontSize: 30,
    color: Colors.black,
    fontWeight: FontWeight.w700,
  );
  static TextStyle font14Black400Weight = TextStyle(
    fontSize:14,
    color: Colors.black,
    fontWeight: FontWeight.w400,
  );

  static TextStyle font24Green700Weight = TextStyle(
    fontSize: 24,
    color: const Color(0xFF4CAF50),
    fontWeight: FontWeight.w700,
  );

  static TextStyle font30green600Weight = TextStyle(
    fontSize: 30,
    color: const Color(0xFF4CAF50),

    fontWeight: FontWeight.w600,
  );

  static TextStyle font14green200Weight = TextStyle(
    fontSize: 14,
    color: const Color(0xFF4CAF50),

    fontWeight: FontWeight.w200,
  );

  static TextStyle font14grey400Weight = TextStyle(
    fontSize: 14,
    color: Colors.grey,
    fontWeight: FontWeight.w400,
  );

  static TextStyle font14LightGrayRegular = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ColorsManager.lightGray,
  );

  static TextStyle buttonstextstyle = TextStyle(
    fontSize: 18,

    fontWeight: FontWeight.w300,
    color: Colors.white,
  );
}
