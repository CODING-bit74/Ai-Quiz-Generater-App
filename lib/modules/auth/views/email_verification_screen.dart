import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_project/modules/auth/controllers/auth_controller.dart';
import 'package:test_project/routes/app_routes.dart';
import 'package:test_project/widgets/custom_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthController _authController = Get.find<AuthController>();
  Timer? _verificationTimer;
  Timer? _cooldownTimer;
  late final String _email;
  bool _checking = false;
  int _resendRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _email = _resolveEmail();
    _startVerificationPolling();
    _syncResendCooldown();
    _startCooldownTicker();
  }

  String _resolveEmail() {
    final args = Get.arguments;
    if (args is Map && args['email'] != null) {
      final email = args['email'].toString().trim();
      if (email.isNotEmpty) {
        return email;
      }
    }

    return _authController.pendingVerificationEmail ?? '';
  }

  void _startVerificationPolling() {
    if (_email.isEmpty) {
      return;
    }

    _verificationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkVerification(showFeedback: false);
    });
  }

  void _syncResendCooldown() {
    if (_email.isEmpty) {
      _resendRemainingSeconds = 0;
      return;
    }

    _resendRemainingSeconds = _authController.getResendSecondsRemaining(_email);
  }

  void _startCooldownTicker() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _authController.getResendSecondsRemaining(_email);
      if (!mounted) {
        return;
      }

      if (remaining == _resendRemainingSeconds) {
        return;
      }

      setState(() {
        _resendRemainingSeconds = remaining;
      });
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_email.isEmpty || _resendRemainingSeconds > 0) {
      return;
    }

    final sent = await _authController.resendVerificationEmail(email: _email);
    if (!mounted || !sent) {
      return;
    }

    setState(_syncResendCooldown);
  }

  Future<void> _checkVerification({required bool showFeedback}) async {
    if (_checking || _email.isEmpty) {
      return;
    }
    _checking = true;
    try {
      await _authController.checkEmailVerificationStatus(
        email: _email,
        showFeedback: showFeedback,
      );
    } finally {
      _checking = false;
    }
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String _formatCountdown(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Email Verification'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Please check your email',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _email.isEmpty
                      ? 'We could not detect your email. Please login again.'
                      : 'Verification link sent to:\n$_email',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                const Text(
                  'We automatically check every 5 seconds.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Obx(
                  () => CustomButton(
                    text: 'Check Verification Now',
                    isLoading: _authController.isVerificationChecking.value,
                    onPressed: _email.isEmpty
                        ? null
                        : () => _checkVerification(showFeedback: true),
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => CustomButton(
                    text: _resendRemainingSeconds > 0
                        ? 'Resend in ${_formatCountdown(_resendRemainingSeconds)}'
                        : 'Resend Verification Email',
                    isLoading: _authController.isResendingVerification.value,
                    onPressed: (_email.isEmpty ||
                            _resendRemainingSeconds > 0 ||
                            _authController.isResendingVerification.value)
                        ? null
                        : _resendVerificationEmail,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.login),
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
