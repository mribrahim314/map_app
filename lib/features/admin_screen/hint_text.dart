import 'package:flutter/material.dart';

class StatusText extends StatelessWidget {
  final String text;

  const StatusText(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: text == "User found"
            ? Colors.green
            : text == "User not found"
                ? Colors.red
                : Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
    );
  }
}