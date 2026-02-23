import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../welcome_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = Get.find<AuthService>();
  bool _isLogin = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && name.isEmpty)) {
      Get.snackbar(
        "Access Denied",
        "Credentials incomplete. Please fill all fields.",
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
      return;
    }

    String? error;
    if (_isLogin) {
      error = await _authService.signIn(email, password);
    } else {
      error = await _authService.signUp(email, password, name);
    }

    if (error == null) {
      Get.offAll(() => const WelcomeScreen());
    } else if (error == "CONFIRM_EMAIL") {
      Get.snackbar(
        "Protocol Initiated",
        "Verification link sent. Check secure frequency (email).",
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.mark_email_read, color: Colors.white),
      );
      setState(() => _isLogin = true);
    } else {
      Get.snackbar(
        "System Error",
        error,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050511), // Deep Void Black
      body: Stack(
        children: [
          // 1. Dynamic Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF050511), // Void
                    Color(0xFF0F172A), // Deep Slate
                    Color(0xFF0B1026), // Navy
                  ],
                ),
              ),
            ),
          ),

          // 2. Cyberpunk Orbs (Glow effects)
          Positioned(
            top: -100,
            right: -100,
            child: _buildGlowOrb(Colors.cyanAccent, 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildGlowOrb(Colors.blueAccent, 250),
          ),

          // 3. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo / Icon
                      Hero(
                        tag: 'auth_logo',
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.3),
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            size: 50,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Glass Panel
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.05),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              children: [
                                // Title Animation
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, -0.2),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    _isLogin
                                        ? "ACCESS TERMINAL"
                                        : "NEW AGENT REGISTRY",
                                    key: ValueKey<bool>(_isLogin),
                                    style: GoogleFonts.orbitron(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 3,
                                      shadows: [
                                        Shadow(
                                          color: Colors.cyanAccent.withOpacity(
                                            0.5,
                                          ),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: Text(
                                    _isLogin
                                        ? "Identify yourself to proceed"
                                        : "Initialize new personnel record",
                                    key: ValueKey<bool>(_isLogin),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                      letterSpacing: 1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 40),

                                // Inputs
                                if (!_isLogin) ...[
                                  _buildCyberInput(
                                    controller: _nameController,
                                    label: "AGENT NAME",
                                    icon: Icons.person_rounded,
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                _buildCyberInput(
                                  controller: _emailController,
                                  label: "CODENAME / EMAIL",
                                  icon: Icons.alternate_email_rounded,
                                ),
                                const SizedBox(height: 20),
                                _buildCyberInput(
                                  controller: _passwordController,
                                  label: "ACCESS KEY",
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                ),
                                const SizedBox(height: 40),

                                // Action Button
                                Obx(
                                  () => _buildCyberButton(
                                    text: _isLogin
                                        ? "GRANT ACCESS"
                                        : "INITIALIZE",
                                    isLoading: _authService.isLoading.value,
                                    onPressed: _submit,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Toggle Button
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            // Clear fields for cleaner UX
                            if (!_authService.isLoading.value) {
                              _emailController.clear();
                              _passwordController.clear();
                            }
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.cyanAccent,
                          splashFactory: NoSplash.splashFactory,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: RichText(
                            key: ValueKey<bool>(_isLogin),
                            text: TextSpan(
                              style: GoogleFonts.orbitron(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                                letterSpacing: 1,
                              ),
                              children: [
                                TextSpan(
                                  text: _isLogin
                                      ? "NO CLEARANCE? "
                                      : "ALREADY AGENT? ",
                                ),
                                TextSpan(
                                  text: _isLogin
                                      ? "REQUEST ACCESS >"
                                      : "LOGIN >",
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 100,
            spreadRadius: 20,
          ),
        ],
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildCyberInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.orbitron(
          color: Colors.white,
          letterSpacing: 1.5,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
            letterSpacing: 1,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.cyanAccent.withOpacity(0.7),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.cyanAccent.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCyberButton({
    required String text,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: LinearGradient(
          colors: [Colors.blue[900]!, Colors.cyan[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
