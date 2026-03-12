import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:test_project/core/utils/validators.dart';
import 'package:test_project/modules/auth/controllers/auth_controller.dart';
import 'package:test_project/routes/app_routes.dart';
import 'package:test_project/widgets/custom_button.dart';
import 'package:test_project/widgets/custom_textfield.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await _authController.forgotPassword(email: _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420.w),
              child: Obx(
                () => Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Reset Password',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Enter your email to receive reset instructions.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: 18.h),
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                        textInputAction: TextInputAction.done,
                      ),
                      SizedBox(height: 20.h),
                      CustomButton(
                        text: 'Send reset link',
                        isLoading: _authController.isLoading.value,
                        onPressed: _submit,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Use the reset link from your email to open the app and continue.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () => Get.offNamed(AppRoutes.login),
                        child: const Text('Back to Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
