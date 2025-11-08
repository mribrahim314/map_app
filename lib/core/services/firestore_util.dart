import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> moveDocument({
  required String fromCollection,
  required String docId,
  required String toCollection,
}) async {
  final sourceRef = FirebaseFirestore.instance.collection(fromCollection).doc(docId);
  final targetRef = FirebaseFirestore.instance.collection(toCollection).doc(docId);

  final doc = await sourceRef.get();

  if (!doc.exists) {
    throw Exception('Document $docId does not exist in $fromCollection');
  }

  await targetRef.set(doc.data()!);
  await sourceRef.delete();

  print('✅ Document $docId moved from $fromCollection to $toCollection');
}