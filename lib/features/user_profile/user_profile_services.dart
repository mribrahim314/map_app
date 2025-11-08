import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:map_app/core/models/user_model.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser!;
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> requestContributorRole(
    String userId,
    //  Box<AppUser> userBox
  ) async {
    final userDocRef = _firestore.collection('users').doc(userId);
    await userDocRef.update({'contributionRequestSent': true});

    // final currentUser = userBox.get('currentUser') as AppUser;
    // final updatedUser = AppUser(
    //   name: currentUser.name,
    //   role: currentUser.role,
    //   requestSent: true,
    //   contributionCount: currentUser.contributionCount,
    // );
    // await userBox.put('currentUser', updatedUser);
  }

  Future<void> cancelContributorRequest(
    String userId,
    // , Box<AppUser> userBox
  ) async {
    final userDocRef = _firestore.collection('users').doc(userId);
    await userDocRef.update({'contributionRequestSent': false});

    // final currentUser = userBox.get('currentUser') as AppUser;
    // final updatedUser = AppUser(
    //   name: currentUser.name,
    //   role: currentUser.role,
    //   requestSent: false,
    //   contributionCount: currentUser.contributionCount,
    // );
    // await userBox.put('currentUser', updatedUser);
  }
}
