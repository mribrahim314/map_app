import 'dart:io';

import 'package:flutter/material.dart';
import 'package:map_app/core/helpers/data.dart';
import 'package:map_app/core/services/image_picker_service.dart';
import 'package:map_app/core/services/upload_image_to_supabase.dart';
import 'package:map_app/core/theming/styles.dart';
import 'package:map_app/core/widgets/app_text_button.dart';
import 'package:map_app/core/widgets/customized_text_field.dart';
import 'package:map_app/core/widgets/image_picker_widget.dart';
import 'package:map_app/features/admin_user_screen/widgets/image_picker2.dart';
import 'package:map_app/features/confirm_screen/drop_down.dart';
import 'package:map_app/core/helpers/spacing.dart';
import 'package:map_app/core/repositories/polygon_repository.dart';
import 'package:map_app/core/repositories/point_repository.dart';

class EditScreen extends StatefulWidget {
  final polygonId;
  final data;
  EditScreen({super.key, this.polygonId, this.data});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  File? _imageFile;
  String? selectedgv = null;
  String? selectedDistrict = null;
  String? selectedCategory = null;
  String? imageURL = null;
  final TextEditingController _messageController = TextEditingController();
  @override
  void initState() {
    super.initState();
    selectedgv = widget.data['Gouvernante'];
    imageURL = widget.data['imageURL'];

    selectedDistrict = widget.data['District'];
    selectedCategory = widget.data['Type'];
    _messageController.text = widget.data['Message'];
  }

  Future<void> _pickImage() async {
    final picker = ImagePickerService();
    final File? pickedImage = await picker.pickImageFromGallery();

    if (pickedImage != null) {
      setState(() {
        _imageFile = pickedImage; // ← This is the key!
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      imageURL = null;
    });
  }

  void setgv(String? value) {
    setState(() {
      selectedDistrict = null;
      selectedgv = value;
    });
  }

  void setDistrict(String? value) {
    setState(() {
      selectedDistrict = value;
    });
  }

  void setCategory(String? value) {
    setState(() {
      selectedCategory = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit infos"), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Edit Data", style: TextStyles.font30green600Weight),
                VerticalSpacing(8),
                Text(
                  "Enter Accurate Informations",
                  style: TextStyles.font14grey400Weight,
                ),

                VerticalSpacing(20),

                ImagePickerWidget2(
                  imageURL: imageURL,
                  imageFile: _imageFile,
                  onImagePicked: _pickImage,
                  onImageRemoved: _removeImage,
                ),
                VerticalSpacing(20),

                CustomizedDropdown(
                  value: selectedgv,
                  onChanged: setgv,
                  hint: "Choose Governorate",
                  items: Data.governorates,
                ),
                VerticalSpacing(20),
                CustomizedDropdown(
                  value: selectedDistrict,
                  onChanged: setDistrict,
                  hint: "Choose District",

                  items: Data.getDistricts(selectedgv),
                ),
                VerticalSpacing(20),
                CustomizedDropdown(
                  value: selectedCategory,
                  onChanged: setCategory,
                  hint: "Choose Category",

                  items: Data.Categories,
                ),

                VerticalSpacing(20),
                CustomizedTextField(controller: _messageController),
                // AppTextFormField(hintText: "password"),
                // VerticalSpacing(20),
                VerticalSpacing(20),
                AppTextButton(
                  buttonText: "Confirm",
                  onPressed: () async {
                    // Validate inputs first (optional but recommended)
                    if (selectedCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select at least a category."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (selectedCategory == "Others" &&
                        _messageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please describe the 'Others' category in the message.",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      String? newImageURL = imageURL;

                      // Upload new image if one was selected
                      if (_imageFile != null) {
                        newImageURL = await uploadImageToSupabase(_imageFile!);
                      }

                      // Prepare updated data
                      final updatedData = {
                        'gouvernante': selectedgv,
                        'district': selectedDistrict,
                        'type': selectedCategory,
                        'message': _messageController.text.trim(),
                        'image_url': newImageURL,
                      };

                      // Update the polygon in PostgreSQL
                      final polygonRepo = PolygonRepository();
                      await polygonRepo.updatePolygon(
                        widget.polygonId,
                        updatedData,
                      );

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Polygon info updated successfully!"),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Pop back to previous screen
                      Navigator.pop(context);
                    } catch (e) {
                      // Handle errors
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Failed to update: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },

                  textStyle: TextStyles.buttonstextstyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
