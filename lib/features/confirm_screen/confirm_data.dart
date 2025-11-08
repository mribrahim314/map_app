// ============================================================================
// CLEANED BY CLAUDE - Fixed import path for drop_down.dart
// ============================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_app/core/cubit/draw_cubit.dart';
import 'package:map_app/core/cubit/coordinates_cubit.dart';
import 'package:map_app/core/helpers/data.dart';
import 'package:map_app/core/helpers/extensions.dart';
import 'package:map_app/core/helpers/spacing.dart';
import 'package:map_app/core/models/pending_submission.dart';
import 'package:map_app/core/models/polygon_model.dart';
import 'package:map_app/core/models/point_model.dart';
import 'package:map_app/core/networking/internet_connexion.dart';
import 'package:map_app/core/repositories/polygon_repository.dart';
import 'package:map_app/core/repositories/point_repository.dart';
import 'package:map_app/core/services/auth_service.dart';
import 'package:map_app/core/services/image_picker_service.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:map_app/core/services/upload_image_to_supabase.dart';
import 'package:map_app/core/theming/styles.dart';
import 'package:map_app/core/widgets/app_text_button.dart';

import 'package:map_app/core/widgets/image_picker_widget.dart';
import 'package:map_app/core/widgets/customized_text_field.dart';
import 'package:map_app/features/confirm_screen/drop_down.dart';
import 'package:provider/provider.dart';

class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  String? selectedgv = null;
  String? selectedDistrict = null;
  String? selectedCategory = null;
  String? selectedParcelSize;
  final TextEditingController _messageController = TextEditingController();
  File? _imageFile;
  bool isLoading = false;
  @override
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
    });
  }

  @override
  Widget build(BuildContext context) {
    void setParcelSize(String? value) {
      setState(() {
        selectedParcelSize = value;
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

    Future<void> recordContribution() async {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.incrementContribution();
    }

    String getTargetCollection(bool isPoint, String userRole) {
      return isPoint ? 'points' : 'polygones';
    }

    Future<void> uploadToDB() async {
      try {
        final now = DateTime.now();
        final dateTimeString =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')} '
            '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}';

        // Get current user from AuthService
        final authService = Provider.of<AuthService>(context, listen: false);
        final currentUser = authService.currentUser;

        if (currentUser == null) {
          throw Exception("User not authenticated");
        }

        final String userRole = currentUser.role;
        final String userId = currentUser.id;

        String? imageURL = null;

        final polygonPoints = context.read<CoordinatesCubit>().state;

        // Convert to LatLng list
        final coordinates = polygonPoints.map((pos) {
          return LatLng(pos.lat.toDouble(), pos.lng.toDouble());
        }).toList();

        final isPoint = coordinates.length == 1;
        if (coordinates.isEmpty) {
          throw Exception("No coordinates provided");
        }

        final targetCollection = getTargetCollection(isPoint, userRole);
        final isAdopted = userRole == 'normal' ? false : true;
        print('Target collection: $targetCollection');

        bool internet = await checkInternet(context);

        if (!internet) {
          // Save to Hive for offline sync
          final coordinatesHive = polygonPoints.map((pos) {
            return {'lat': pos.lat.toDouble(), 'lng': pos.lng.toDouble()};
          }).toList();

          final submission = PendingSubmission(
            district: selectedDistrict,
            gouvernante: selectedgv,
            coordinates: coordinatesHive,
            type: selectedCategory,
            message: _messageController.text.trim(),
            imageURL: _imageFile != null ? _imageFile!.path : null,
            userId: userId,
            isAdopted: isAdopted,
            parcelSize: isPoint ? selectedParcelSize : null,
            date: dateTimeString,
            collection: targetCollection,
          );

          final box = await Hive.openBox<PendingSubmission>(
            'pendingSubmissions',
          );

          await box.add(submission);

          print("No internet: saved locally to Hive");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("No internet connexion, data saved locally"),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Upload image to Supabase if available
          if (_imageFile != null) {
            try {
              imageURL = await uploadImageToSupabase(_imageFile!);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Image upload failed: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              print('Image upload error: $e');
            }
          }

          // Upload to PostgreSQL database
          if (isPoint) {
            // Create point in database
            final pointRepo = PointRepository();
            final point = PointModel(
              district: selectedDistrict!,
              gouvernante: selectedgv!,
              type: selectedCategory!,
              coordinate: coordinates.first,
              message: _messageController.text.trim(),
              imageUrl: imageURL,
              userId: userId,
              isAdopted: isAdopted,
              date: DateTime.now(),
              parcelSize: selectedParcelSize,
            );

            await pointRepo.createPoint(point, district: '');
          } else {
            // Create polygon in database
            final polygonRepo = PolygonRepository();
            final polygon = PolygonModel(
              district: selectedDistrict!,
              gouvernante: selectedgv!,
              type: selectedCategory!,
              coordinates: coordinates,
              message: _messageController.text.trim(),
              imageUrl: imageURL,
              userId: userId,
              isAdopted: isAdopted,
              date: DateTime.now(),
            );

            await polygonRepo.createPolygon(polygon);
          }

          // Record contribution
          await recordContribution();
          print('Data uploaded successfully');
        }

        // Clear drawing state
        final drawcubit = context.read<DrawModeCubit>();
        final polygoncubit = context.read<CoordinatesCubit>();
        drawcubit.disable();
        polygoncubit.clear();

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Contribution recorded!")));
        }

        if (mounted) context.pop();
      } catch (e) {
        print('Upload error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to upload contribution: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text("Confirm Polygone"), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Confirm Data", style: TextStyles.font30green600Weight),
                VerticalSpacing(8),
                Text(
                  "Enter Accurate Informations",
                  style: TextStyles.font14grey400Weight,
                ),

                VerticalSpacing(20),
                ImagePickerWidget(
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
                if (context.watch<CoordinatesCubit>().state.length == 1)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VerticalSpacing(20),
                      CustomizedDropdown(
                        value: selectedParcelSize,
                        onChanged: setParcelSize,
                        hint: "Select parcel size",
                        items: ['Small', 'Medium', 'Large'],
                      ),
                    ],
                  ),

                VerticalSpacing(20),
                CustomizedTextField(controller: _messageController),

                VerticalSpacing(20),
                AppTextButton(
                  buttonText: isLoading ? "Uploading..." : "Confirm",
                  onPressed: isLoading
                      ? () {}
                      : () async {
                          final bool isConnected =
                              await InternetConnectionChecker
                                  .instance
                                  .hasConnection;

                          // if (!isConnected) {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     const SnackBar(
                          //       content: Text(
                          //         "No internet connection. Please check your network and try again.",
                          //       ),
                          //       backgroundColor: Colors.orange,
                          //       behavior: SnackBarBehavior.floating,
                          //     ),
                          //   );
                          //   return;
                          // }
                          if (selectedCategory == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please select at least a category.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return; // Stop the upload
                          }

                          if (selectedCategory == "Others" &&
                              (_messageController.text.isEmpty)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please fill the message with the type you think it is",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return; // Stop the upload
                          }

                          await uploadToDB();
                        },

                  textStyle: TextStyles.buttonstextstyle,
                ),
                VerticalSpacing(20),

                VerticalSpacing(20),

                VerticalSpacing(20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
