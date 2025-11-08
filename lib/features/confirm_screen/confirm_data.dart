import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:map_app/core/cubit/draw_cubit.dart';
import 'package:map_app/core/cubit/coordinates_cubit.dart';
import 'package:map_app/core/helpers/data.dart';
import 'package:map_app/core/helpers/extensions.dart';
import 'package:map_app/core/helpers/spacing.dart';
import 'package:map_app/core/models/pending_submission.dart';
import 'package:map_app/core/models/project_model.dart';
import 'package:map_app/core/networking/internet_connexion.dart';
import 'package:map_app/core/networking/project_repository.dart';
import 'package:map_app/core/services/image_picker_service.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:map_app/core/services/upload_image_to_supabase.dart';
import 'package:map_app/core/theming/styles.dart';
import 'package:map_app/core/widgets/app_text_button.dart';

import 'package:map_app/core/widgets/image_picker_widget.dart';
import 'package:map_app/core/widgets/customized_text_field.dart';
import 'package:map_app/features/draw_sceen/drop_down.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
  String? selectedProjectId;
  final TextEditingController _messageController = TextEditingController();
  File? _imageFile;
  bool isLoading = false;
  List<Project> availableProjects = [];
  bool isLoadingProjects = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userRole = userDoc.data()?['role'] ?? 'viewer';
      final repository = ProjectRepository();

      List<Project> projects;
      if (userRole == 'admin') {
        projects = await repository.getActiveProjects();
      } else {
        projects = await repository.getUserProjects(user.uid);
      }

      if (mounted) {
        setState(() {
          availableProjects = projects;
          isLoadingProjects = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingProjects = false;
        });
      }
    }
  }

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

    Future<void> recordContribution(String userId) async {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'contributionCount': FieldValue.increment(1),
      });
      // final box = Hive.box<AppUser>('userBox');
      // final cachedUser = box.get('currentUser');

      // if (cachedUser != null) {
      //   final updatedUser = cachedUser.copyWith(
      //     contributionCount: cachedUser.contributionCount + 1,
      //   );

      // await box.put('currentUser', updatedUser);
      // }
    }

    String getTargetCollection(bool isPoint, String userRole) {
      return isPoint ? 'points' : 'polygones';
    }

    Future<void> uploadToDB() async {
      setState(() {
        isLoading = true;
      });

      try {
        final now = DateTime.now();
        final dateTimeString =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')} '
            '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}';

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please log in first to submit contributions."),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          throw Exception("User document not found");
        }
        final String? userRole = userDoc.get('role') as String?;

        if (userRole == null) {
          throw Exception("User role not defined");
        }
        String? imageURL = null;
        // if (_imageFile != null) {
        //   try {
        //     imageURL = await uploadImageToSupabase(_imageFile!);
        //   } catch (e) {
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       SnackBar(
        //         content: Text("Upload failed: $e"),
        //         backgroundColor: Colors.red,
        //       ),
        //     );
        //     print(e);
        //   }
        // }
        final polygonPoints = context.read<CoordinatesCubit>().state;
        final
        // List<Map<String, double>>
        coordinates = polygonPoints.map((pos) {
          return GeoPoint(pos.lat.toDouble(), pos.lng.toDouble());
        }).toList();
        final isPoint = coordinates.length == 1;
        if (coordinates.isEmpty) {
          throw Exception("No coordinates provided. Please draw on the map first.");
        }
        final targetCollection = getTargetCollection(isPoint, userRole);
        final isAdopted = userRole == 'normal' ? false : true;
        print(targetCollection);
        bool internet = await checkInternet(context);

        if (!internet) {
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
            userId: user.uid,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No internet connexion, data saved locally"),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          if (_imageFile != null) {
            try {
              imageURL = await uploadImageToSupabase(_imageFile!);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Upload failed: $e"),
                  backgroundColor: Colors.red,
                ),
              );
              print(e);
            }
          }

          // Get actual project ID from selected project name
          String? actualProjectId;
          if (selectedProjectId != null) {
            final selectedProject = availableProjects.firstWhere(
              (p) => p.name == selectedProjectId,
              orElse: () => availableProjects.first,
            );
            actualProjectId = selectedProject.id;
          }

          final data = await FirebaseFirestore.instance
              .collection(targetCollection)
              .add({
                "District": selectedDistrict,
                "Gouvernante": selectedgv,
                "coordinates": coordinates,
                "Type": selectedCategory,
                "Message": _messageController.text.trim(),
                "imageURL": imageURL,
                "userId": user.uid,
                "isAdopted": isAdopted,
                "parcelSize": isPoint ? selectedParcelSize : null,
                "Date": dateTimeString,
                "projectId": actualProjectId,
                // "TimeStamp": Timestamp.fromDate(DateTime.now()),
              });
          await recordContribution(user.uid);
          print(data.id);
        }
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
        print(e);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to upload contribution. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
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
                if (isLoadingProjects)
                  const Center(child: CircularProgressIndicator())
                else if (availableProjects.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No projects available. Contact admin to be added to a project.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  CustomizedDropdown(
                    value: selectedProjectId,
                    onChanged: (value) {
                      setState(() {
                        selectedProjectId = value;
                      });
                    },
                    hint: "Select Project",
                    items: availableProjects
                        .map((project) => project.name)
                        .toList(),
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
                          if (availableProjects.isNotEmpty && selectedProjectId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please select a project.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

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
