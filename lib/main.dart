import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:map_app/core/models/pending_submission.dart';
import 'package:map_app/core/routing/app_router.dart';
import 'package:map_app/features/cnrs_app.dart';
import 'package:map_app/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/adapters.dart';

void main() async {
  await Hive.initFlutter();
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      await Supabase.initialize(
        url: 'https://tyvalriflbijrytdtyqc.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5dmFscmlmbGJpanJ5dGR0eXFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNjUwMzAsImV4cCI6MjA3Mjc0MTAzMH0.6l2ZDsf7VDDUkzFdrV9rvhQwnvGveLf5cpUff0ER8JY',
      );

      Hive.registerAdapter(PendingSubmissionAdapter());

      runApp(CNRSapp(appRouter: AppRouter()));
    },
    (error, stack) {
      print("Uncaught error: $error");
      print("Stack: $stack");
    },
  );
}
