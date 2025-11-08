// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:map_app/core/theming/colors.dart';

// class UserService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<void> _changePassword(BuildContext context) async {
//     final oldPasswordController = TextEditingController();
//     final newPasswordController = TextEditingController();

//     await showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Change Password'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: oldPasswordController,
//               decoration: const InputDecoration(labelText: 'Current Password'),
//               obscureText: true,
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: newPasswordController,
//               decoration: const InputDecoration(labelText: 'New Password'),
//               obscureText: true,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             style: ElevatedButton.styleFrom(
//               foregroundColor: Colors.white,
//               backgroundColor: ColorsManager.mainGreen, // <- ✅ Update button
//             ),
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (newPasswordController.text.length < 6) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Password must be at least 6 characters'),
//                   ),
//                 );
//                 return;
//               }

//               setState(() => _isLoading = true);

//               try {
//                 final user = _auth.currentUser!;
//                 final credential = EmailAuthProvider.credential(
//                   email: user.email!,
//                   password: oldPasswordController.text,
//                 );
//                 await user.reauthenticateWithCredential(credential);
//                 await user.updatePassword(newPasswordController.text);

//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Password updated!')),
//                 );
//                 Navigator.pop(ctx);
//               } on FirebaseAuthException catch (e) {
//                 String message = 'Failed to update password';
//                 if (e.code == 'wrong-password') {
//                   message = 'Incorrect current password';
//                 }
//                 ScaffoldMessenger.of(
//                   context,
//                 ).showSnackBar(SnackBar(content: Text(message)));
//               } catch (e) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('An error occurred')),
//                 );
//               } finally {
//                 setState(() => _isLoading = false);
//               }
//             },
//             child: const Text('Update'),
//             style: ElevatedButton.styleFrom(
//               foregroundColor: Colors.white,
//               backgroundColor: ColorsManager.mainGreen,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _requestContributorRole() async {
//     setState(() => _isLoading = true);

//     try {
//       final user = _auth.currentUser!;
//       final userDocRef = _firestore.collection('users').doc(user.uid);

//       await userDocRef.update({'contributionRequestSent': true});

//       // _user = AppUser(
//       //   name: _user.name,
//       //   role: _user.role,
//       //   requestSent: true,
//       //   contributionCount: _user.contributionCount,
//       // );

//       // await _userBox.put('currentUser', _user);

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Request sent!')));
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Failed to send request')));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _cancelRequest() async {
//     setState(() => _isLoading = true);

//     try {
//       final user = _auth.currentUser!;
//       final userDocRef = _firestore.collection('users').doc(user.uid);

//       await userDocRef.update({'contributionRequestSent': false});

//       // _user = AppUser(
//       //   name: _user.name,
//       //   role: _user.role,
//       //   requestSent: false,
//       //   contributionCount: _user.contributionCount,
//       // );

//       // await _userBox.put('currentUser', _user);

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Request canceled')));
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Failed to cancel')));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _logout() async {
//     final shouldLogout = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Confirm Logout'),
//           content: const Text('Are you sure you want to log out?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false), // Cancel
//               child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.of(context).pop(true), // Confirm
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red, // or your theme color
//               ),
//               child: const Text(
//                 'Logout',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ],
//         );
//       },
//     );

//     // Only proceed if user confirmed
//     if (shouldLogout == true) {
//       await FirebaseAuth.instance.signOut();
//       // final box = Hive.box<AppUser>('userBox');
//       // await box.delete('currentUser');
//       context.pushReplacementNamed(Routes.logInScreen);
//     }
//   }
// }
