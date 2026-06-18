import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'practice_mode_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/websocket_service.dart';
import 'profile_screen.dart';
import 'ai_coach_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeDashboardView(),
      const PracticeModeScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.home, "Home"),
                _buildNavItem(1, LucideIcons.compass, "Practice"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RewriteToolCard extends StatefulWidget {
  const RewriteToolCard({super.key});

  @override
  State<RewriteToolCard> createState() => _RewriteToolCardState();
}

class _RewriteToolCardState extends State<RewriteToolCard> {
  final TextEditingController _inputController = TextEditingController();
  String _selectedTone = "Confident";
  String _rewrittenText = "";
  String _suggestion = "";
  bool _isLoading = false;

  final List<String> _tones = ["Confident", "Professional", "Friendly", "Warm"];

  void _performRewrite() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _rewrittenText = "";
      _suggestion = "";
    });

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/rewrite"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "tone": _selectedTone,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rewrittenText = data["improved"] ?? "";
          _suggestion = data["suggestion"] ?? "";
        });
      } else {
        _simulateFallbackRewrite(text);
      }
    } catch (e) {
      _simulateFallbackRewrite(text);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _simulateFallbackRewrite(String text) {
    final textLower = text.toLowerCase();
    String improved = text;
    String suggestion = "Focus on confidence and clarity.";
    
    if (textLower.contains("coffee")) {
      improved = "Hey! I'd love to grab a coffee sometime this week if you're free. Let me know what day works best for you!";
      suggestion = "Emphasize clear dates and a friendly opening.";
    } else if (textLower.contains("interview") || textLower.contains("job")) {
      improved = "I bring a strong set of skills that align directly with the requirements of this role, and I'm eager to contribute.";
      suggestion = "Highlight mutual value and avoid apologizing.";
    } else if (textLower.contains("sorry")) {
      improved = "Thank you for your patience. I'll make sure to get this updated right away.";
      suggestion = "Rephrase apologies into positive confirmations.";
    } else {
      improved = "Thanks for reaching out! Let's connect sometime soon to discuss the details.";
      suggestion = "Keep it concise and collaborative.";
    }
    
    setState(() {
      _rewrittenText = improved;
      _suggestion = suggestion;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _rewrittenText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Polished message copied!", style: GoogleFonts.inter(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.pencil, color: Theme.of(context).colorScheme.secondary, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                "Message Rewrite Engine",
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
              ),
            ),
            child: TextField(
              controller: _inputController,
              maxLines: 2,
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onBackground, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: "Paste your raw or awkward draft message...",
                hintStyle: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.35),
                  fontSize: 13,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tones.map((tone) {
                final isSelected = _selectedTone == tone;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(tone),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTone = tone;
                        });
                      }
                    },
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    ),
                    backgroundColor: Colors.transparent,
                    selectedColor: Theme.of(context).colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.onBackground.withOpacity(0.12),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _performRewrite,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text("Polish Message", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          if (_rewrittenText.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "POLISHED VERSION",
                  style: GoogleFonts.plusJakartaSans(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.copy, size: 14),
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  onPressed: _copyToClipboard,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _rewrittenText,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  if (_suggestion.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _suggestion,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class HomeDashboardView extends ConsumerStatefulWidget {
  const HomeDashboardView({super.key});

  @override
  ConsumerState<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends ConsumerState<HomeDashboardView> {
  final TextEditingController _chatController = TextEditingController();
  int _selectedSegment = 0;

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "S";
    final parts = name.split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  void _startChat([String? initialMessage]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AICoachChatScreen(initialMessage: initialMessage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final userName = auth.user?.name ?? "Alex";
    final initials = _getInitials(auth.user?.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F0F13), const Color(0xFF14151D), const Color(0xFF1B1A24)]
              : [const Color(0xFFF6F6F9), const Color(0xFFFFFFFF), const Color(0xFFEDEDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          children: [
            // Top Dashboard Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Good evening,",
                      style: GoogleFonts.plusJakartaSans(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: GoogleFonts.plusJakartaSans(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5E5CE6), Color(0xFF0A84FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5E5CE6).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Custom Glassmorphic Segment Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSegment = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedSegment == 0
                              ? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedSegment == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "AI Coach",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _selectedSegment == 0
                                ? Theme.of(context).colorScheme.onBackground
                                : Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSegment = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedSegment == 1
                              ? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedSegment == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Rewrite Engine",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _selectedSegment == 1
                                ? Theme.of(context).colorScheme.onBackground
                                : Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            if (_selectedSegment == 1) ...[
              const RewriteToolCard(),
            ] else ...[
              // Main Launch Card (Start Conversation)
              
              const SizedBox(height: 32),

              // Quick Actions Grid Header
              Text(
                "QUICK ASSISTANTS",
                style: GoogleFonts.plusJakartaSans(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.35),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Quick Actions Horizontal Carousel
              
              const SizedBox(height: 32),

              // Recent Conversations Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "RECENT SESSIONS",
                    style: GoogleFonts.plusJakartaSans(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.35),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRecentSessionRow(context, "Interview preparation coaching", "15 mins ago", "I am nervous about my interview"),
              _buildRecentSessionRow(context, "Friend communication block", "1 day ago", "My friend is ignoring me, what should I do?"),
              _buildRecentSessionRow(context, "Social anxiety check-in", "3 days ago", "I feel nervous about presenting in front of people"),

              const SizedBox(height: 32),

              // Bottom Quick Prompt Text Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF171721).withOpacity(0.8) : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onBackground, fontSize: 14.5),
                        decoration: InputDecoration(
                          hintText: "Ask AI Coach anything...",
                          hintStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.35), fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            _startChat(val.trim());
                            _chatController.clear();
                          }
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_chatController.text.trim().isNotEmpty) {
                          _startChat(_chatController.text.trim());
                          _chatController.clear();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.arrowUp, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    String subtitle,
    String prompt,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _startChat(prompt),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessionRow(BuildContext context, String title, String time, String initialPrompt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.04), width: 0.8),
      ),
      child: InkWell(
        onTap: () => _startChat(initialPrompt),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.messageSquare, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4), size: 12),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: GoogleFonts.plusJakartaSans(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                )
              ],
            ),
            Icon(LucideIcons.chevronRight, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.24), size: 14),
          ],
        ),
      ),
    );
  }
}



