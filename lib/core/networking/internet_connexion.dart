// lib/utils/internet_helper.dart

import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

Future<bool> checkInternetAndNotify(BuildContext context) async {
  final bool isConnected = await InternetConnectionChecker.instance.hasConnection;

  if (!isConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "No internet connection. Please check your network and try again.",
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }

  return true;
}

Future<bool> checkInternet(BuildContext context) async {
  final bool isConnected = await InternetConnectionChecker.instance.hasConnection;

  if (!isConnected) {
    return false;
  }

  return true;
}
