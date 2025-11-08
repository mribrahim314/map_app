import 'package:flutter/material.dart';
import 'package:map_app/core/cubit/user_role_cubit.dart';
import 'package:map_app/core/models/pending_submission.dart';
import 'package:map_app/core/services/auth_service.dart';
import 'package:map_app/core/theming/colors.dart';
import 'package:map_app/features/admin_screen/admin_screen.dart';
import 'package:map_app/features/contribution_screen/contribution_screen.dart';
import 'package:map_app/features/main_screen/stack_screen.dart';
import 'package:map_app/features/user_profile/user_profile_screen.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _isLoading = true;
  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _navItems;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserRoleFromCache();
    sendPendingSubmissions();
  }

  Future<void> _loadUserRoleFromCache() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) {
        throw Exception('No authenticated user');
      }

      final role = user.role;
      setState(() {
        _userRole = role;
        _isLoading = false;
        _setupNavigation();
      });
      context.read<UserRoleCubit>().setRole(role);
    } catch (e) {
      print("Error loading cached role: $e");
      setState(() {
        _userRole = 'normal';
        _isLoading = false;
        _setupNavigation();
      });
    }
  }

  void _setupNavigation() {
    _pages = [StackScreen(), ContributionsScreen(), UserProfileScreen()];
    _navItems = [
      BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Explore'),
      BottomNavigationBarItem(
        icon: Icon(Icons.share_location),
        label: 'Contributions',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    if (_userRole == 'admin') {
      _pages.add(AdminScreen());
      _navItems.add(
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedFontSize: 14,
        unselectedFontSize: 14,
        selectedItemColor: ColorsManager.mainGreen,
        unselectedItemColor: Colors.grey,
        items: _navItems,
      ),
    );
  }
}
