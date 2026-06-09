import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'practice_mode_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/websocket_service.dart';
import 'live_conversation_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';

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

class HomeDashboardView extends ConsumerWidget {
  const HomeDashboardView({super.key});

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "S";
    final parts = name.split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final userName = auth.user?.name ?? "Alex";
    final initials = _getInitials(auth.user?.name);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        children: [
          // Top Dashboard
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

          // Main Launch Card (Minimalist premium)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const LiveConversationScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Ready to listen",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF34C759),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Start Session",
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Real-time speaking prompts, calming tempo adjustments, and immediate feedback.",
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(LucideIcons.mic, color: Theme.of(context).colorScheme.onPrimary, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Tap to begin",
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats Panels
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  context,
                  "Confidence Level",
                  "84%",
                  "+3.2% VS PREV",
                  LucideIcons.checkCircle2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  context,
                  "Speaking Pace",
                  "128 WPM",
                  "OPTIMAL PACE",
                  LucideIcons.gauge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Vocal Balance Overview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "VOCAL BALANCE METRICS",
                      style: GoogleFonts.plusJakartaSans(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Icon(LucideIcons.info, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4), size: 12),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    _buildMetricBar(context, "Clarity", 0.88),
                    const SizedBox(height: 14),
                    _buildMetricBar(context, "Calm Pacing", 0.76),
                    const SizedBox(height: 14),
                    _buildMetricBar(context, "Warmth", 0.81),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // EXHIBITION DEMO MODE PANEL
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Color(0xFFBF5AF2), size: 14),
              const SizedBox(width: 6),
              Text(
                "EXHIBITION DEMO PANEL",
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFBF5AF2),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDemoScenarioCard(
            context,
            ref,
            "Anxious Interviewee",
            "I hope I'm not bothering you, but please hire me, I'm begging.",
            "Interview",
            const Color(0xFF0A84FF),
            LucideIcons.briefcase,
          ),
          _buildDemoScenarioCard(
            context,
            ref,
            "Awkward Text",
            "Why are you ignoring me?",
            "Dating",
            const Color(0xFFFF9F0A),
            LucideIcons.heart,
          ),
          _buildDemoScenarioCard(
            context,
            ref,
            "Difficult Workplace Chat",
            "You need to fix this right now.",
            "Workplace",
            const Color(0xFFFF375F),
            LucideIcons.briefcase,
          ),
          _buildDemoScenarioCard(
            context,
            ref,
            "Dry Friendship Reply",
            "k",
            "Friendship",
            const Color(0xFF32ADE6),
            LucideIcons.messageSquare,
          ),
          const SizedBox(height: 24),

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
              Text(
                "SEE ALL",
                style: GoogleFonts.plusJakartaSans(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSessionRow(context, "Conversation Practice", "15 mins ago", "86%", true),
          _buildSessionRow(context, "Work Meeting", "1 day ago", "79%", false),
          _buildSessionRow(context, "Speaking Practice", "3 days ago", "82%", true),
        ],
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, String value, String subText, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4), size: 12),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBar(BuildContext context, String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "${(value * 100).toInt()}%",
              style: GoogleFonts.plusJakartaSans(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.04),
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
            minHeight: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionRow(BuildContext context, String title, String time, String score, bool isPositive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.04), width: 0.8),
      ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.04),
              border: Border.all(
                color: isPositive ? Theme.of(context).colorScheme.onBackground.withOpacity(0.3) : Theme.of(context).colorScheme.onBackground.withOpacity(0.12),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              score,
              style: GoogleFonts.plusJakartaSans(
                color: isPositive ? Theme.of(context).colorScheme.onBackground : Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDemoScenarioCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    String text,
    String contextName,
    Color color,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        final ws = ref.read(webSocketServiceProvider.notifier);
        ws.selectedContext = contextName;
        ws.mode = "chat";
        ws.sendText(text);
        
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => LiveConversationScreen(
              initialContext: contextName,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          contextName.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            color: color,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "\"$text\"",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PracticeModulesView extends StatelessWidget {
  const PracticeModulesView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        children: [
          Text(
            "PRACTICE CENTER",
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Practice Modules",
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Short practice sessions designed to improve confidence, calm your pace, and manage difficult conversations.",
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          _buildModuleCard(
            context,
            "Speaking Calmly",
            "Slow down your speaking speed and practice using warm rhetoric transitions.",
            "BEGINNER",
            LucideIcons.smile,
          ),
          _buildModuleCard(
            context,
            "Difficult Workplace Chats",
            "Maintain your composure and manage breathing under stress or pressure.",
            "INTERMEDIATE",
            LucideIcons.shieldAlert,
          ),
          _buildModuleCard(
            context,
            "Assertive Conversations",
            "Speak clearly and with positive confidence. Reduce stuttering or filler words.",
            "ADVANCED",
            LucideIcons.briefcase,
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, String title, String desc, String level, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), width: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.04),
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08)),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7), size: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  level,
                  style: GoogleFonts.plusJakartaSans(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Duration: 10m",
                style: GoogleFonts.plusJakartaSans(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text(
                    "START SESSION",
                    style: GoogleFonts.plusJakartaSans(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.play, color: Theme.of(context).colorScheme.onBackground, size: 9),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
