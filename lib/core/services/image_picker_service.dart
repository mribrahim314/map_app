// services/image_picker_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image != null ? File(image.path) : null;
  }

  // Take a photo using camera
  Future<File?> takePhotoWithCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    return photo != null ? File(photo.path) : null;
  }
}