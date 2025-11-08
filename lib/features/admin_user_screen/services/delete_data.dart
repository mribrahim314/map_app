// ============================================================================
// CLEANED BY CLAUDE - Removed Firebase/Firestore dependencies
// ============================================================================

import 'package:map_app/core/repositories/polygon_repository.dart';
import 'package:map_app/core/repositories/point_repository.dart';
import 'package:map_app/core/repositories/user_repository.dart';

Future<void> DeleteDataForUser(String userId) async {
  try {
    final polygonRepo = PolygonRepository();
    final pointRepo = PointRepository();
    final userRepo = UserRepository();

    // Delete all polygons for this user
    await polygonRepo.deletePolygonsByUserId(userId);

    // Delete all points for this user
    await pointRepo.deletePointsByUserId(userId);

    // Reset user contribution count
    final user = await userRepo.getUserById(userId);
    if (user != null) {
      await userRepo.updateContributionCount(userId, 0);
    }

    print('Data successfully deleted for userId: $userId');
  } catch (e) {
    print('Error during deletion: $e');
    rethrow;
  }
}