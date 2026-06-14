import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'practice_mode_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/websocket_service.dart';
import 'analytics_screen.dart';
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
      const AnalyticsScreen(),
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
                _buildNavItem(1, LucideIcons.barChart2, "Insights"),
                _buildNavItem(2, LucideIcons.compass, "Practice"),
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

class HomeDashboardView extends ConsumerStatefulWidget {
  const HomeDashboardView({super.key});

  @override
  ConsumerState<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends ConsumerState<HomeDashboardView> {
  final TextEditingController _chatController = TextEditingController();

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

    return SafeArea(
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
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
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
                  width: 44,
                  height: 44,
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
                        blurRadius: 10,
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
          const SizedBox(height: 32),

          // Main Launch Card (Start Conversation)
          GestureDetector(
            onTap: () => _startChat(),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E5CE6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "SOCIALSYNC AI COACH",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF5E5CE6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Start Conversation",
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Chat freely with your personal coach about social anxiety, communication help, texting guidance, and more.",
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.mic, color: Colors.black, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Tap to begin",
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // AI Chat Access Card
          GestureDetector(
            onTap: () => _startChat(),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.04), width: 0.8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.sparkles, color: Theme.of(context).colorScheme.secondary, size: 18),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Access AI Coach Chat",
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Get immediate help and empathetic advice.",
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.24), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Quick Actions Grid Header
          Text(
            "QUICK ACTIONS",
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Quick Actions Horizontal Carousel
          SizedBox(
            height: 130,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickActionCard(
                  context,
                  "Interview Help",
                  "I am nervous about my upcoming interview.",
                  "I am nervous about my interview",
                  LucideIcons.briefcase,
                  const Color(0xFF0A84FF),
                ),
                const SizedBox(width: 12),
                _buildQuickActionCard(
                  context,
                  "Message Rewrite",
                  "Ask the coach how to write or reply to a text.",
                  "I don't know what to text my coworker, can you help me write a polite reply?",
                  LucideIcons.pencil,
                  const Color(0xFFFF9F0A),
                ),
                const SizedBox(width: 12),
                _buildQuickActionCard(
                  context,
                  "Conversation Starter",
                  "Get suggestions to kickstart a conversation.",
                  "Can you give me a good conversation starter for meeting new friends?",
                  LucideIcons.messageCircle,
                  const Color(0xFF34C759),
                ),
                const SizedBox(width: 12),
                _buildQuickActionCard(
                  context,
                  "Social Anxiety Support",
                  "Talk about feelings of failure or anxiety.",
                  "I failed my exam and feel hopeless and anxious.",
                  LucideIcons.heart,
                  const Color(0xFFFF375F),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Recent Conversations Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "RECENT CONVERSATIONS",
                style: GoogleFonts.plusJakartaSans(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRecentSessionRow(context, "Interview preparation coaching", "15 mins ago", "I am nervous about my interview"),
          _buildRecentSessionRow(context, "Friend communication block", "1 day ago", "My friend is ignoring me, what should I do?"),
          _buildRecentSessionRow(context, "Social anxiety check-in", "3 days ago", "I feel nervous about presenting in front of people"),

          const SizedBox(height: 32),

          // Bottom Quick Prompt Text Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onBackground, fontSize: 14.5),
                    decoration: InputDecoration(
                      hintText: "Ask AI Coach anything...",
                      hintStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.arrowUp, color: Theme.of(context).colorScheme.primary, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
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



