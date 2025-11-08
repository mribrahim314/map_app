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
  await Hive.initFlutter();
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

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

      // Initialize Supabase for image storage
      await Supabase.initialize(
        url: 'https://tyvalriflbijrytdtyqc.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5dmFscmlmbGJpanJ5dGR0eXFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNjUwMzAsImV4cCI6MjA3Mjc0MTAzMH0.6l2ZDsf7VDDUkzFdrV9rvhQwnvGveLf5cpUff0ER8JY',
      );

      // Register Hive adapters for offline storage
      Hive.registerAdapter(PendingSubmissionAdapter());

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthService()),
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
