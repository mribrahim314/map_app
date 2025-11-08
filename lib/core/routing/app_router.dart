import 'package:flutter/material.dart';

import 'package:map_app/core/routing/routes.dart';
import 'package:map_app/features/about_and_feedback/about_screen.dart';
import 'package:map_app/features/admin_screen/export_screen.dart';
import 'package:map_app/features/confirm_screen/confirm_data.dart';
import 'package:map_app/features/login_and_signup/login_screen.dart';
import 'package:map_app/features/main_screen/main_screen.dart';
import 'package:map_app/features/map_page/map_screen.dart';
import 'package:map_app/features/onboarding/onboarding_screen.dart';
import 'package:map_app/features/login_and_signup/sign_up_screen.dart';
import 'package:map_app/features/user_profile/user_profile_screen.dart';

class AppRouter {
  Route generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.onBoardScreen:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case Routes.logInScreen:
        return MaterialPageRoute(builder: (_) => LoginScreen());

      case Routes.mapScreen:
        return MaterialPageRoute(builder: (_) => MapScreen());

      case Routes.mainScreen:
        return MaterialPageRoute(builder: (_) => MainScreen());

      case Routes.drawScreen:
        return MaterialPageRoute(builder: (_) => const DrawScreen());

      case Routes.signUpScreen:
        return MaterialPageRoute(builder: (_) => SignUpScreen());
      case Routes.userProfile:
        return MaterialPageRoute(builder: (_) => UserProfileScreen());

      case Routes.aboutScreen:
        return MaterialPageRoute(builder: (_) => AboutScreen());

      // case Routes.feedbackScreen:
      //   return MaterialPageRoute(builder: (_) => FeedbackScreen());
     
      case Routes.exportScreen:
        return MaterialPageRoute(builder: (_) => ExportScreen());
      

      default:
        return _errorRoute();
    }
  }

  // Helper method to handle undefined routes
  static Route _errorRoute() {
    return MaterialPageRoute(
      builder: (_) =>
          const Scaffold(body: Center(child: Text('ERROR: Page not found!'))),
    );
  }
}
