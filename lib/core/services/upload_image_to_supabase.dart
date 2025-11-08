import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

Future<String?> uploadImageToSupabase(File imageFile) async {
  try {
    final supabase = Supabase.instance.client;
    final id = const Uuid().v4();
    final filePath = 'uploads/$id.jpg';

    // Upload the file
    final storageResponse = await supabase.storage
        .from('images')
        .upload(filePath, imageFile);

    if (storageResponse.isEmpty) {
      throw Exception('Upload response is empty. Upload may have failed.');
    }

    // Get public URL
    final publicUrl = supabase.storage.from('images').getPublicUrl(filePath);
    return publicUrl;
  } catch (e) {
    // You can log or rethrow — but avoid showing UI here (no ScaffoldMessenger)
    print('Image upload error: $e');
    rethrow; // Let the caller handle the error
  }
}
