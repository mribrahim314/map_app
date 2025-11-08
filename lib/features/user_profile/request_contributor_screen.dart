import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map_app/core/helpers/spacing.dart';
import 'package:map_app/core/theming/styles.dart';
import 'package:map_app/core/widgets/app_text_button.dart';
import 'package:map_app/core/widgets/customized_text_field.dart';

class RequestContributorScreen extends StatefulWidget {
  const RequestContributorScreen({super.key});

  @override
  State<RequestContributorScreen> createState() =>
      _RequestContributorScreenState();
}

class _RequestContributorScreenState extends State<RequestContributorScreen> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _currentStatus;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (mounted) {
      setState(() {
        _currentStatus = userDoc.data()?['contributorStatus'] ?? 'none';
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for your request'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Update user document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'contributorStatus': 'pending',
        'contributionRequestSent': true,
        'contributorRequestReason': _reasonController.text.trim(),
        'contributorRequestDate': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Contributor request submitted! Please wait for admin approval.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Contributor Access'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request Contributor Access',
                  style: TextStyles.font30green600Weight,
                ),
                VerticalSpacing(10),
                Text(
                  'To become a contributor and submit data to projects, you need approval from an admin.',
                  style: TextStyles.font14grey400Weight,
                ),
                VerticalSpacing(20),
                if (_currentStatus == 'pending') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_empty, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your request is pending approval',
                            style: TextStyle(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  VerticalSpacing(20),
                ] else if (_currentStatus == 'approved') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You are already an approved contributor!',
                            style: TextStyle(color: Colors.green.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  VerticalSpacing(20),
                ] else if (_currentStatus == 'rejected') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your previous request was rejected. You can submit a new request.',
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  VerticalSpacing(20),
                ],
                Text(
                  'Reason for Request',
                  style: TextStyles.font14grey400Weight,
                ),
                VerticalSpacing(10),
                CustomizedTextField(
                  controller: _reasonController,
                  hint: 'Please explain why you want to become a contributor...',
                  maxLines: 5,
                ),
                VerticalSpacing(30),
                if (_currentStatus != 'pending' && _currentStatus != 'approved')
                  AppTextButton(
                    buttonText: _isLoading ? 'Submitting...' : 'Submit Request',
                    onPressed: _isLoading ? () {} : _submitRequest,
                    textStyle: TextStyles.buttonstextstyle,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
