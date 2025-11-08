// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:map_app/core/helpers/data.dart';
// import 'package:map_app/core/theming/styles.dart';
// import 'package:map_app/core/widgets/app_text_button.dart';
// import 'package:map_app/features/admin_screen/exprot_service.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:device_info_plus/device_info_plus.dart';

// class ExportScreen extends StatefulWidget {
//   const ExportScreen({super.key});

//   @override
//   State<ExportScreen> createState() => _ExportScreenState();
// }

// class _ExportScreenState extends State<ExportScreen> {
//   String? _selectedCategory;

//   Future<void> saveGeoJsonToFile(String geoJsonString, String fileName) async {
//     try {
//       Directory? directory;
//       // Check and request permission
//       if (Platform.isAndroid) {
//         final androidInfo = await DeviceInfoPlugin().androidInfo;
//         final sdkInt = androidInfo.version.sdkInt;

//         bool granted = false;

//         if (sdkInt >= 30) {
//           final status = await Permission.manageExternalStorage.request();
//           granted = status.isGranted;
//         } else {
//           final status = await Permission.storage.request();
//           granted = status.isGranted;
//         }

//         if (!granted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('❌ Storage permission not granted')),
//           );
//           return;
//         }

//         // ✅ Set the download path directly
//         directory = Directory('/storage/emulated/0/Download');
//       } else if (Platform.isIOS) {
//         directory = await getApplicationDocumentsDirectory();
//       }

//       if (directory == null) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('❌ Could not get directory')));
//         return;
//       }

//       final path = '${directory.path}/$fileName';
//       final file = File(path);

//       await file.writeAsString(geoJsonString);

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('✅ File saved at: $path')));

//       print('✅ GeoJSON file saved at: $path'); 
//     } catch (e) {
//       print('❌ Error saving GeoJSON: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('❌ Error saving file')));
//     }
//   }

//   void _toggleCategory(String category) {
//     setState(() {
//       if (_selectedCategory == category) {
//         _selectedCategory = null; // unselect if already selected
//       } else {
//         _selectedCategory = category; // select new one
//       }
//     });
//   }
// void setCategory(String? value) {
//       setState(() {
//         _selectedCategory = value;
//       });
//     }
//   void _export() async {
//     if (_selectedCategory == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select at least one category')),
//       );
//       return;
//     }

//     // Show selected categories
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text('Exporting ... ')));

//     String geojson = await generateFilteredGeoJson(
//       polygonsCollection: "polygones",
//       pointsCollection: "points",
//       filterType: _selectedCategory!,
//     );
//     String englishType = _selectedCategory!.split(' - ').last.trim();
//     await saveGeoJsonToFile(geojson, '${englishType}.geojson');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Export Data'),
//         backgroundColor: Colors.green.shade800,
//         foregroundColor: Colors.white,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text(
//               'Select one or more categories to export:',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),

//             // Scrollable checkbox list
//             Expanded(
//               child: ListView.separated(
//                 itemCount: Data.Categories.length,
//                 separatorBuilder: (context, index) => const Divider(),
//                 itemBuilder: (context, index) {
//                   final category = Data.Categories[index];
//                   final isSelected = _selectedCategory == category;

//                   return RadioListTile<String>(
//                     title: Text(category),
//                     value: category,
//                     groupValue: _selectedCategory,
//                     onChanged: (value) {
//                       if (value != null) _toggleCategory(value);
//                     },
//                     activeColor: Colors.green,
//                     contentPadding: EdgeInsets.zero,
//                   );
//                 },
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Export Button
//             AppTextButton(
//               buttonText: "Export Selected",
//               textStyle: TextStyles.buttonstextstyle,
//               onPressed: _export,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
