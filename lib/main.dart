import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_app/core/models/pending_submission.dart';
import 'package:map_app/core/routing/app_router.dart';
import 'package:map_app/features/cnrs_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:map_app/core/config/app_config.dart';
import 'package:map_app/core/services/auth_service.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Hive for local storage
      await Hive.initFlutter();

      // Load environment variables from .env file
      await AppConfig.initialize();

      // Validate configuration
      if (!AppConfig.validate()) {
        print('Warning: Some configuration values are missing. Please check your .env file.');
      }

      // Initialize Supabase for image storage using environment variables
      if (AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty) {
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          anonKey: AppConfig.supabaseAnonKey,
        );
        print('Supabase initialized successfully');
      } else {
        print('Warning: Supabase configuration missing. Image upload will not work.');
      }

      print('API Base URL: ${AppConfig.apiBaseUrl}');

      // Register Hive adapters for offline storage
      Hive.registerAdapter(PendingSubmissionAdapter());

      // Initialize AuthService and restore session
      final authService = AuthService();
      await authService.initializeSession();

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authService),
          ],
          child: CNRSapp(appRouter: AppRouter()),
        ),
      );
    },
    (error, stack) {
      print("Uncaught error: $error");
      print("Stack: $stack");
    },
  );
}
