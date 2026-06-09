import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'practice_session_screen.dart';

class PracticeModeScreen extends StatelessWidget {
  const PracticeModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Practice Mode",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Select a specialized AI Coach Persona to begin your simulated roleplay conversation.",
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Scenarios linked to AI Personas
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildScenarioCard(
                    context: context,
                    title: "Job Interview Coach",
                    description: "Practice answering tough behavioral questions and managing professional pacing.",
                    icon: LucideIcons.briefcase,
                    color: const Color(0xFF0A84FF),
                    coachName: "Interview Coach",
                    contextName: "Interview",
                  ),
                  const SizedBox(height: 16),
                  _buildScenarioCard(
                    context: context,
                    title: "Dating Coach",
                    description: "Work on maintaining engaging, warm small talk and avoiding dry pauses.",
                    icon: LucideIcons.heart,
                    color: const Color(0xFFFF9F0A),
                    coachName: "Dating Coach",
                    contextName: "Dating",
                  ),
                  const SizedBox(height: 16),
                  _buildScenarioCard(
                    context: context,
                    title: "Public Speaking Coach",
                    description: "Deliver presentations while the coach monitors your confidence, pace, and clarity.",
                    icon: LucideIcons.mic,
                    color: const Color(0xFF32ADE6),
                    coachName: "Public Speaking Coach",
                    contextName: "Public Speaking",
                  ),
                  const SizedBox(height: 16),
                  _buildScenarioCard(
                    context: context,
                    title: "Networking Coach",
                    description: "Practice asserting value, asking follow-up questions, and active listening.",
                    icon: LucideIcons.heartHandshake,
                    color: const Color(0xFFFF375F),
                    coachName: "Networking Coach",
                    contextName: "Networking",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String coachName,
    required String contextName,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PracticeSessionScreen(
              coachName: coachName,
              contextName: contextName,
              coachIcon: icon,
              themeColor: color,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.04), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(LucideIcons.chevronRight, color: Colors.white24, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
