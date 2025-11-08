import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:map_app/core/cubit/draw_cubit.dart';
import 'package:map_app/core/helpers/extensions.dart';
import 'package:map_app/core/routing/routes.dart';
import 'package:map_app/core/theming/colors.dart';
import 'package:map_app/features/admin_user_screen/screens/map_screen_with_appbar.dart';
import 'package:map_app/features/map_page/map_screen.dart';
import 'package:map_app/features/user_profile/card_user_profile_screen.dart';
import 'package:map_app/features/user_profile/user_header.dart';
import 'package:maplibre/maplibre.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String _userRole = 'normal'; // Default fallback
  String _userName = 'Unknown User';
  bool _isLoading = true;
  bool _userRequestSent = false;
  int _userContributionCount = 0;
  // late Box<AppUser> _userBox;
  // late AppUser _user;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _userRole = data?['role'] as String? ?? 'normal';
          _userRequestSent = data?['contributionRequestSent'] as bool? ?? false;
          _userContributionCount = data?['contributionCount'] as int? ?? 0;
          _userName =
              (data?['email'] as String?)
                  ?.replaceFirst('@test.com', '') // Remove the domain
                  .trim() ??
              'Unknown User';
        });
      } else {
        setState(() {
          _userRole = 'normal';
          _userName = 'Unknown User';
          _userRequestSent = false;
          _userContributionCount = 0;
        });
      }
    } catch (e) {
      print("Error loading user profile: $e");

      setState(() {
        _userRole = 'normal';
        _userName = 'Unknown User';
        _userRequestSent = false;
        _userContributionCount = 0;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: ColorsManager.mainGreen, // <- ✅ Update button
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                  ),
                );
                return;
              }

              setState(() => _isLoading = true);

              try {
                final user = _auth.currentUser!;
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: oldPasswordController.text,
                );
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPasswordController.text);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated!')),
                );
                Navigator.pop(ctx);
              } on FirebaseAuthException catch (e) {
                String message = 'Failed to update password';
                if (e.code == 'wrong-password') {
                  message = 'Incorrect current password';
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('An error occurred')),
                );
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Update'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: ColorsManager.mainGreen,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestContributorRole() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser!;
      final userDocRef = _firestore.collection('users').doc(user.uid);

      await userDocRef.update({'contributionRequestSent': true});

      // _user = AppUser(
      //   name: _user.name,
      //   role: _user.role,
      //   requestSent: true,
      //   contributionCount: _user.contributionCount,
      // );

      // await _userBox.put('currentUser', _user);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request sent!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send request')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelRequest() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser!;
      final userDocRef = _firestore.collection('users').doc(user.uid);

      await userDocRef.update({'contributionRequestSent': false});

      // _user = AppUser(
      //   name: _user.name,
      //   role: _user.role,
      //   requestSent: false,
      //   contributionCount: _user.contributionCount,
      // );

      // await _userBox.put('currentUser', _user);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request canceled')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to cancel')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // or your theme color
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    // Only proceed if user confirmed
    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      // final box = Hive.box<AppUser>('userBox');
      // await box.delete('currentUser');
      context.pushReplacementNamed(Routes.logInScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // User Header (Centered)
                      UserHeader(name: _userName, role: _userRole),

                      const SizedBox(height: 20),

                      // Contributions Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.analytics,
                              color: Colors.blue,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contributions',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${_userContributionCount} contribution(s)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Request Status
                      if (_userRequestSent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your request to become a contributor is pending approval.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.amber[800]),
                                ),
                              ),
                              IconButton(
                                onPressed: _isLoading ? null : _cancelRequest,
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                tooltip: 'Cancel Request',
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      if (_userRole == 'normal' && !_userRequestSent)
                        CustomizedUserProfileScreenCard(
                          icon: Icons.upgrade_outlined,
                          primaryText: "Request Contributor Role",
                          ontapped: () async {
                            await _requestContributorRole();
                          },
                        ),

                      const SizedBox(height: 16),

                      CustomizedUserProfileScreenCard(
                        icon: Icons.lock_reset,
                        primaryText: "Change Password",
                        ontapped: _isLoading ? null : _changePassword,
                      ),

                      const SizedBox(height: 16),

                      CustomizedUserProfileScreenCard(
                        icon: Icons.info,
                        primaryText: "About",
                        ontapped: () {
                          context.pushNamed(Routes.aboutScreen);
                        },
                      ),

                      const SizedBox(height: 16),
                      CustomizedUserProfileScreenCard(
                        icon: Icons.logout_outlined,
                        primaryText: "Log Out ",
                        ontapped: () async {
                          await _logout();
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomizedUserProfileScreenCard(
                        icon: Icons.download_outlined,
                        primaryText: "Download Map",
                        ontapped: () {
                          final drawCubit = context.read<DrawModeCubit>();
                          drawCubit.enablePolygon(); // enable polygon drawing

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapScreenWithAppBar(
                                showDownloadButton: true,
                                // showDownloadButton: true,
                                child: MapScreen(
                                  // your original map implementation
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
