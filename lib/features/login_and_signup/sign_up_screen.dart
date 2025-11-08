import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map_app/core/helpers/extensions.dart';
import 'package:map_app/core/helpers/spacing.dart';
import 'package:map_app/core/models/user_model.dart';
import 'package:map_app/core/networking/internet_connexion.dart';
import 'package:map_app/core/routing/routes.dart';
import 'package:map_app/core/services/hive_service.dart';
import 'package:map_app/core/theming/colors.dart';
import 'package:map_app/core/theming/styles.dart';
import 'package:map_app/core/widgets/app_text_button.dart';
import 'package:map_app/core/widgets/app_text_form_field.dart';
import 'package:map_app/features/login_and_signup/widgets/have_Account.dart';
import 'package:map_app/features/login_and_signup/widgets/terms_and_condition.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isObscure = true;
  bool _isConfirmObscure = true;

  void _togglePasswordVisibility() {
    setState(() {
      _isObscure = !_isObscure;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmObscure = !_isConfirmObscure;
    });
  }

  @override
  Widget build(BuildContext context) {
    Future<void> _onSignUpPressed() async {
      bool online = await checkInternetAndNotify(context);
      if (!online) return;
      try {
        if (_formKey.currentState!.validate()) {
          final String _email = _usernameController.text.trim() + "@test.com";

          final _userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: _email,
                password: _passwordController.text.trim(),
              );

          print(_userCredential);

          final userDoc = FirebaseFirestore.instance
              .collection('users')
              .doc(_userCredential.user!.uid);

          await userDoc.set({
            'email': _email,
            'username': _usernameController.text.trim(),
            'role': 'viewer', // Default role is viewer
            'status': 'active', // Status can be: pending, active, rejected
            'contributorStatus': 'none', // none, pending, approved, rejected
            'contributionCount': 0,
            'contributionRequestSent': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Fetch the newly created user data from Firestore
          final docSnapshot = await userDoc.get();
          final userData = docSnapshot.data();

          // if (userData != null) {
          //   // Convert to your AppUser model
          //   final user = AppUser(
          //     name: _usernameController.text
          //         .trim(), // or userData['name'] if saved
          //     role: userData['role'] ?? 'normal',
          //     contributionCount: userData['contributionCount'] ?? 0,
          //     requestSent: userData['contributionRequestSent'] ?? false,
          //   );

          //   // Save user to Hive via your HiveService
          //   final hiveService = HiveService();
          //   await hiveService.saveUser(user);
          // }

          // No need for SharedPreferences anymore
          // await saveUserRole('normal');  <-- remove this line if it’s SharedPreferences

          context.pushReplacementNamed(Routes.mainScreen);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created successfully!")),
          );
        }
      } catch (e) {
        print(e);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create Account",
                    style: TextStyles.font30green600Weight,
                  ),
                  VerticalSpacing(8),
                  Text(
                    "Please fill in the details below to create a new account.",
                    style: TextStyles.font14grey400Weight,
                  ),
                  VerticalSpacing(20),
                  AppTextFormField(
                    hintText: "Username or ID",
                    controller: _usernameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username or ID';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  VerticalSpacing(20),
                  AppTextFormField(
                    hintText: "Password",
                    controller: _passwordController,
                    isObscureText: _isObscure,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility_off : Icons.visibility,
                        color: ColorsManager.gray,
                        size: 18,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  VerticalSpacing(20),
                  AppTextFormField(
                    hintText: "Confirm Password",
                    controller: _confirmPasswordController,
                    isObscureText: _isConfirmObscure,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm Password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmObscure
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: ColorsManager.gray,
                        size: 18,
                      ),
                      onPressed: _toggleConfirmPasswordVisibility,
                    ),
                  ),
                  VerticalSpacing(20),
                  AppTextButton(
                    buttonText: "Sign Up",
                    onPressed: () async {
                      await _onSignUpPressed();
                    },
                    textStyle: TextStyles.buttonstextstyle,
                  ),
                  VerticalSpacing(20),
                  // ForgetPassword(),
                  VerticalSpacing(20),
                  TermsAndConditionsText(),
                  VerticalSpacing(20),
                  HaveAccountText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
