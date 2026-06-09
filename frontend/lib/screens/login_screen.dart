import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter your email and password.");
      return;
    }
    if (!email.contains("@")) {
      _showError("Please enter a valid email address.");
      return;
    }

    final errorMessage = await ref.read(authProvider.notifier).login(
      email: email,
      password: password,
    );

    if (errorMessage == null && mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else if (mounted) {
      // Show exact error message to help with things like "Email not confirmed"
      _showError(errorMessage ?? "Login failed. Please try again.");
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
          // Soft Calming Depth Glows
          Positioned(
            top: -200,
            right: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5E5CE6).withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            left: -150,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A84FF).withOpacity(0.03),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),
                  Text(
                    "Welcome back.",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Sign in to continue your progress.",
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(flex: 2),

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
                            "Signing in...",
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                  ] else ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Email Address",
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          cursorColor: Colors.white,
                          keyboardType: TextInputType.emailAddress,
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
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Password",
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final email = _emailController.text.trim();
                                if (email.isEmpty) {
                                  _showError("Please enter your email first to reset.");
                                  return;
                                }
                                final success = await ref.read(authProvider.notifier).resetPassword(email);
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Password reset email sent.", style: GoogleFonts.inter(fontSize: 13)),
                                      backgroundColor: const Color(0xFF34C759),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      margin: const EdgeInsets.all(20),
                                    )
                                  );
                                }
                              },
                              child: Text(
                                "Forgot?",
                                style: GoogleFonts.inter(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          cursorColor: Colors.white,
                          obscureText: true,
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
                    ),
                    const SizedBox(height: 40),

                    GestureDetector(
                      onTap: _handleLogin,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Sign In",
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            transitionDuration: const Duration(milliseconds: 600),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Enter Exhibition Demo Mode",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const SignupScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                              transitionDuration: const Duration(milliseconds: 400),
                            ),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: "Sign Up",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
