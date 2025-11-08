// ============================================================================
// CLEANED BY CLAUDE - Fixed import paths
// ============================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:map_app/core/helpers/data.dart';
import 'package:map_app/core/networking/internet_connexion.dart';
import 'package:map_app/core/theming/styles.dart';
import 'package:map_app/core/widgets/app_text_button.dart';
import 'package:map_app/core/widgets/search_row.dart';
import 'package:map_app/features/admin_screen/exprot_service.dart';
import 'package:map_app/features/admin_screen/hint_text.dart';
import 'package:map_app/features/confirm_screen/drop_down.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:share_plus/share_plus.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String? _selectedCategory;
  String? _selectedType;
  String? _selectedUserId = null;
  String foundText = "";
  final TextEditingController _userNameController = TextEditingController();
  final categoriesItems = ["All", ...Data.Categories];
  final usersItems = [
    "All data",
    "Shown data",
    "Non shown data",
    "Specific User",
  ];

  Future<void> saveGeoJsonToFile(String geoJsonString, String fileName) async {
    try {
      Directory? directory;
      // Check and request permission
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        bool granted = false;

        if (sdkInt >= 30) {
          final status = await Permission.manageExternalStorage.request();
          granted = status.isGranted;
        } else {
          final status = await Permission.storage.request();
          granted = status.isGranted;
        }

        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Storage permission not granted')),
          );
          return;
        }

        // ✅ Set the download path directly
        directory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Could not get directory')));
        return;
      }

      final path = '${directory.path}/$fileName';
      final file = File(path);

      await file.writeAsString(geoJsonString);
      if (await file.exists()) {
        await SharePlus.instance.share(
          ShareParams(
            text: "$fileName\nFile created with CEDAR app ",
            files: [XFile(path)],
          ),
        );
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ File saved ')));

      print('✅ GeoJSON file saved at: $path');
    } catch (e) {
      print('❌ Error saving GeoJSON: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error saving file')));
    }
  }

  void setCategory(String? value) {
    setState(() {
      _selectedCategory = value;
    });
  }

  void setUser(String? value) {
    setState(() {
      _selectedType = value;
    });
  }

  void _exportCategory() async {
    try {
      bool online = await checkInternetAndNotify(context);
      if (!online) return;

      if (_selectedCategory == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please a category')));
        return;
      }
      if (_selectedType == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a Type')));
        return;
      }
      if (_selectedType == "Specific User" && _selectedUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid user name')),
        );
        return;
      }

      // Show selected categories
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exporting ... ')));
      print(_selectedUserId);
      String geojson = await generateFilteredGeoJson(
        polygonsCollection: "polygones",
        pointsCollection: "points",
        filtredCategory: _selectedCategory!,
        filtredType: _selectedType!,
        userId: _selectedUserId,
      );
      String selectedType = (_selectedType == "Specific User")
          ? _userNameController.text.trim()
          : _selectedType!;
      String myFileName =
          "${_selectedCategory!.split(' - ').last.trim()} - ${selectedType}";
      await saveGeoJsonToFile(geojson, '${myFileName}.geojson');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error $e ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select a category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            CustomizedDropdown(
              value: _selectedCategory,
              onChanged: setCategory,
              hint: "Category",
              items: categoriesItems,
            ),

            const SizedBox(height: 20),
            const Text(
              'Select type of data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            CustomizedDropdown(
              value: _selectedType,
              onChanged: setUser,
              hint: "Type",
              items: usersItems,
            ),
            const SizedBox(height: 20),
            if (_selectedType == "Specific User")
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter User Name',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (_selectedType == "Specific User")
                    SearchRow(
                      userNameController: _userNameController,
                      onPressed: () async {
                        setState(() {
                          foundText = "Searching ...";
                        });
                        String search;
                        final trimmed = _userNameController.text.trim();
                        final suffix = '@test.com';
                        if (trimmed.endsWith(suffix))
                          search = trimmed;
                        else
                          search = trimmed + suffix;
                        _selectedUserId = await findUserIdByEmail(search);
                        if (_selectedUserId == null)
                          setState(() {
                            foundText = "User not found";
                          });
                        else
                          setState(() {
                            foundText = "User found";
                          });
                      },
                    ),
                  StatusText(foundText),
                ],
              ),
            const SizedBox(height: 30),

            // Export Button
            AppTextButton(
              buttonText: "Export Selected",
              textStyle: TextStyles.buttonstextstyle,
              onPressed: _exportCategory,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
