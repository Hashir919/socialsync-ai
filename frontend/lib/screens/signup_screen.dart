import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  void _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError("Please fill in all fields.");
      return;
    }

    if (password.length < 8) {
      _showError("Password must be at least 8 characters.");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match.");
      return;
    }

    final errorMessage = await ref.read(authProvider.notifier).register(
      name: name,
      email: email,
      password: password,
    );

    if (errorMessage == null && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
        (route) => false,
      );
    } else if (mounted) {
      _showError(errorMessage ?? "Signup failed. Email might already be in use.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        elevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // Calm Depth Glows
          Positioned(
            top: -200,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A84FF).withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -150,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5E5CE6).withOpacity(0.03),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Text(
                    "Create Account.",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Your personal AI communication coach.",
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 40),

                  if (authState.isLoading) ...[
                    Center(
                      child: Column(
                        children: [
                          const SpinKitDoubleBounce(
                            color: Colors.white54,
                            size: 24,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Creating your profile...",
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField("Full Name", _nameController, false),
                        const SizedBox(height: 24),
                        _buildInputField("Email Address", _emailController, false, TextInputType.emailAddress),
                        const SizedBox(height: 24),
                        _buildInputField("Password", _passwordController, true),
                        const SizedBox(height: 24),
                        _buildInputField("Confirm Password", _confirmPasswordController, true),
                      ],
                    ),
                    const SizedBox(height: 40),

                    GestureDetector(
                      onTap: _handleSignup,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Sign Up",
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, bool isPassword, [TextInputType type = TextInputType.text]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          cursorColor: Colors.white,
          obscureText: isPassword,
          keyboardType: type,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            filled: true,
            fillColor: const Color(0xFF1C1C1E).withOpacity(0.5),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
          ),
        ),
      ],
    );
  }
}
