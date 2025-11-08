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
import 'package:map_app/features/login_and_signup/widgets/dont_have_acccount.dart';
import 'package:map_app/features/login_and_signup/widgets/terms_and_condition.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;

  void _togglePasswordVisibility() {
    setState(() {
      _isObscure = !_isObscure;
    });
  }

  @override
  Widget build(BuildContext context) {
    Future<void> _onLoginPressed() async {
      bool online = await checkInternetAndNotify(context);
      if (!online) return;

      try {
        if (_formKey.currentState!.validate()) {
          final authService = Provider.of<AuthService>(context, listen: false);
          final String email = _usernameController.text.trim() + "@test.com";
          final String password = _passwordController.text.trim();

          // Sign in with PostgreSQL
          await authService.signIn(
            email: email,
            password: password,
          );

          if (!mounted) return;

          context.pushReplacementNamed(Routes.mainScreen);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Logging in...")),
          );
        }
      } catch (e) {
        print('Login error: $e');
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
                  Text("Welcome Back", style: TextStyles.font30green600Weight),
                  VerticalSpacing(8),
                  Text(
                    "Please enter your credentials to access your account.",
                    style: TextStyles.font14grey400Weight,
                  ),
                  VerticalSpacing(20),
                  AppTextFormField(
                    hintText: "Username or ID",
                    controller: _usernameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username or ID';
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
                        return 'Please enter your password';
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
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  VerticalSpacing(20),
                  AppTextButton(
                    buttonText: "Log In",
                    onPressed: () async {
                      await _onLoginPressed();
                    },
                    // onPressed: () {},
                    textStyle: TextStyles.buttonstextstyle,
                  ),
                  VerticalSpacing(20),
                  // ForgetPassword(),
                  VerticalSpacing(20),
                  TermsAndConditionsText(),
                  VerticalSpacing(20),
                  DontHaveAccountText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
