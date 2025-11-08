import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> DeleteDataForUser(String userId) async {
  try {
    final firestore = FirebaseFirestore.instance;
    // Supprimer les polygones
    final polygonesQuery = firestore
        .collection('polygones')
        .where('userId', isEqualTo: userId);
    final polygonesSnapshot = await polygonesQuery.get();
    for (var doc in polygonesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Supprimer les points
    final pointsQuery = firestore
        .collection('points')
        .where('userId', isEqualTo: userId);
    final pointsSnapshot = await pointsQuery.get();
    for (var doc in pointsSnapshot.docs) {
      await doc.reference.delete();
    }
  await firestore
        .collection('users')
        .doc(userId)
        .update({'contributionCount': 0});

    print('Données supprimées avec succès pour userId: $userId');
  } catch (e) {
    print('Erreur lors de la suppression : $e');
    rethrow; // Optionnel : pour propager l'erreur si besoin
  }
}