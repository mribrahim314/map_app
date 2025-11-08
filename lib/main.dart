import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:map_app/core/models/pending_submission.dart';
import 'package:map_app/core/routing/app_router.dart';
import 'package:map_app/features/cnrs_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:map_app/core/database/database_service.dart';
import 'package:map_app/core/database/db_config.dart';
import 'package:map_app/core/services/auth_service.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Hive for local storage
      await Hive.initFlutter();

      // Load environment variables from .env file
      await DbConfig.initialize();

      // Validate configuration
      if (!DbConfig.validate()) {
        print('Warning: Some configuration values are missing. Please check your .env file.');
      }

      // Initialize PostgreSQL database connection
      DatabaseService.initialize(
        host: DbConfig.host,
        port: DbConfig.port,
        databaseName: DbConfig.databaseName,
        username: DbConfig.username,
        password: DbConfig.password,
      );

      // Test database connection
      try {
        final dbService = DatabaseService.instance;
        final isConnected = await dbService.testConnection();
        if (!isConnected) {
          print('Warning: Database connection failed. Please check your PostgreSQL configuration.');
        } else {
          print('Successfully connected to PostgreSQL database');
        }
      } catch (e) {
        print('Database initialization error: $e');
        print('Please ensure PostgreSQL is running and credentials are correct.');
      }

      // Initialize Supabase for image storage using environment variables
      if (DbConfig.supabaseUrl.isNotEmpty && DbConfig.supabaseAnonKey.isNotEmpty) {
        await Supabase.initialize(
          url: DbConfig.supabaseUrl,
          anonKey: DbConfig.supabaseAnonKey,
        );
        print('Supabase initialized successfully');
      } else {
        print('Warning: Supabase configuration missing. Image upload will not work.');
      }

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
