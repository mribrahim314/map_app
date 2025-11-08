import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:map_app/core/cubit/draw_cubit.dart';
import 'package:map_app/core/cubit/coordinates_cubit.dart';

import 'package:map_app/core/cubit/polygone_cubit.dart';
import 'package:map_app/core/cubit/user_role_cubit.dart';
import 'package:map_app/core/routing/app_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:map_app/core/theming/colors.dart';

import 'package:map_app/features/main_screen/main_screen.dart';
import 'package:map_app/features/onboarding/onboarding_screen.dart';

class CNRSapp extends StatelessWidget {
  final AppRouter appRouter;
  const CNRSapp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CoordinatesCubit>(create: (context) => CoordinatesCubit()),
        BlocProvider<DrawModeCubit>(create: (context) => DrawModeCubit()),
        // BlocProvider<PolygonCubitGl>(create: (context) => PolygonCubitGl()),
        BlocProvider<PolygonCubit>(create: (context) => PolygonCubit()),
        BlocProvider<UserRoleCubit>(create: (context) => UserRoleCubit()),
        // BlocProvider<MapViewCubit>(create: (context) => MapViewCubit()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(500, 729.6),
        minTextAdapt: true,
        child: MaterialApp(
          // initialRoute: Routes.logInScreen,
          title: 'Map_App',
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance
                .userChanges(), // Listen to user changes
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // While waiting for the auth state
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
                // If user is authenticated, show home screen
                return const MainScreen();
              }
              // If no user is authenticated, show the sign-up page
              return const OnboardingScreen();
            },
          ),
          onGenerateRoute: appRouter.generateRoute,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: ColorsManager.mainGreen,
            scaffoldBackgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
