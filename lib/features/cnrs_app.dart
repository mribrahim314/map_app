import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:map_app/core/cubit/draw_cubit.dart';
import 'package:map_app/core/cubit/coordinates_cubit.dart';
import 'package:map_app/core/cubit/polygone_cubit.dart';
import 'package:map_app/core/cubit/user_role_cubit.dart';
import 'package:map_app/core/routing/app_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:map_app/core/theming/colors.dart';
import 'package:map_app/features/main_screen/main_screen.dart';
import 'package:map_app/features/onboarding/onboarding_screen.dart';
import 'package:map_app/core/services/auth_service.dart';

class CNRSapp extends StatelessWidget {
  final AppRouter appRouter;
  const CNRSapp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth service provider
        ChangeNotifierProvider(create: (_) => AuthService()),
        // Bloc providers
        BlocProvider<CoordinatesCubit>(create: (context) => CoordinatesCubit()),
        BlocProvider<DrawModeCubit>(create: (context) => DrawModeCubit()),
        BlocProvider<PolygonCubit>(create: (context) => PolygonCubit()),
        BlocProvider<UserRoleCubit>(create: (context) => UserRoleCubit()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(500, 729.6),
        minTextAdapt: true,
        child: Consumer<AuthService>(
          builder: (context, authService, _) {
            return MaterialApp(
              title: 'Map_App',
              home: authService.isAuthenticated
                  ? const MainScreen()
                  : const OnboardingScreen(),
              onGenerateRoute: appRouter.generateRoute,
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                primaryColor: ColorsManager.mainGreen,
                scaffoldBackgroundColor: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}
