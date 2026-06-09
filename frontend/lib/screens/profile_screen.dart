import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;
  
  bool _weeklyInsights = true;
  bool _gentlePacing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _nameController.text = user.name ?? '';
      }
    });
  }

  void _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      final success = await ref.read(authProvider.notifier).updateProfile(newName);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Profile updated successfully.", style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    }
    setState(() {
      _isEditingName = false;
    });
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "S";
    final parts = name.split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final initials = _getInitials(user?.name);
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // Gentle ambient glow
          Positioned(
            top: -150,
            left: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBF5AF2).withOpacity(0.04),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                    children: [
                      // Avatar
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5E5CE6), Color(0xFF0A84FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5E5CE6).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // User Info
                      if (_isEditingName) ...[
                        TextField(
                          controller: _nameController,
                          cursorColor: Colors.white,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          onSubmitted: (_) => _saveName(),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: _saveName,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Save",
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user?.name ?? "Alex",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _nameController.text = user?.name ?? "";
                                  _isEditingName = true;
                                });
                              },
                              child: const Icon(LucideIcons.edit2, color: Colors.white38, size: 16),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          user?.email ?? "alex@example.com",
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Account Settings Section
                      Text(
                        "Preferences",
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Column(
                          children: [
                            _buildPreferenceSwitch(
                              "Weekly Insights",
                              "Receive personalized progress summaries.",
                              _weeklyInsights,
                              (val) => setState(() => _weeklyInsights = val),
                            ),
                            Divider(color: Colors.white.withOpacity(0.04), height: 1),
                            _buildPreferenceSwitch(
                              "Gentle Pacing Prompts",
                              "Softer visual cues during live sessions.",
                              _gentlePacing,
                              (val) => setState(() => _gentlePacing = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Logout Section
                      GestureDetector(
                        onTap: _handleLogout,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF453A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFF453A).withOpacity(0.2)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Sign Out",
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFF453A),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPreferenceSwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF34C759),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: const Color(0xFF3A3A3C),
          ),
        ],
      ),
    );
  }
}
