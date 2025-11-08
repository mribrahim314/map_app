// ============================================================================
// CLEANED BY CLAUDE - Migrated from Firebase to AuthService
// ============================================================================

import 'package:map_app/core/services/auth_service.dart';

class UserService {
  final AuthService _authService;

  UserService(this._authService);

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    // First verify old password by attempting sign in
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }

    // Re-authenticate with old password
    await _authService.signIn(
      email: user.email,
      password: oldPassword,
    );

    // If successful, change password
    await _authService.changePassword(newPassword);
  }

  Future<void> requestContributorRole() async {
    await _authService.sendContributionRequest();
  }

  Future<void> cancelContributorRequest() async {
    // This would need to be implemented in AuthService/UserRepository
    // For now, just throw an error or implement in UserRepository
    throw UnimplementedError('Cancel contribution request not yet implemented');
  }
}
