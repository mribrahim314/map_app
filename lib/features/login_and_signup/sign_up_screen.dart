import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:map_app/core/helpers/extensions.dart';
import 'package:map_app/core/helpers/spacing.dart';
import 'package:map_app/core/networking/internet_connexion.dart';
import 'package:map_app/core/routing/routes.dart';
import 'package:map_app/core/services/auth_service.dart';
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
          final authService = Provider.of<AuthService>(context, listen: false);
          final String email = _usernameController.text.trim() + "@test.com";
          final String password = _passwordController.text.trim();

          // Create user with PostgreSQL
          await authService.signUp(
            email: email,
            password: password,
            role: 'normal',
          );

          if (!mounted) return;

          context.pushReplacementNamed(Routes.mainScreen);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created successfully!")),
          );
        }
      } catch (e) {
        print('Sign up error: $e');
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
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
