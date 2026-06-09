import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/websocket_service.dart';

class LiveConversationScreen extends ConsumerStatefulWidget {
  final String? initialContext;
  final String? initialPersona;

  const LiveConversationScreen({
    super.key,
    this.initialContext,
    this.initialPersona,
  });

  @override
  ConsumerState<LiveConversationScreen> createState() => _LiveConversationScreenState();
}

class _LiveConversationScreenState extends ConsumerState<LiveConversationScreen> with TickerProviderStateMixin {
  late AnimationController _waveformController;
  late AnimationController _pulseController;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _contexts = [
    "Interview",
    "Dating",
    "Friendship",
    "Workplace",
    "Networking",
    "Family",
    "Public Speaking"
  ];

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ws = ref.read(webSocketServiceProvider.notifier);
      if (widget.initialContext != null) {
        ws.selectedContext = widget.initialContext!;
      }
      if (widget.initialPersona != null) {
        ws.selectedPersona = widget.initialPersona!;
      }
      ws.connect();
    });
  }

  @override
  void dispose() {
    _waveformController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = ref.watch(webSocketServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Subtle accent glow behind visualizer
          if (ws.isListening)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    double opacity = 0.01 + (_pulseController.value * 0.02);
                    return Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0A84FF).withOpacity(opacity),
                      ),
                    );
                  },
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 18),
                        ),
                      ),
                      Text(
                        ws.selectedPersona.isNotEmpty ? ws.selectedPersona : "Communication Coach",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: ws.isListening ? const Color(0xFF34C759).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ws.isListening ? const Color(0xFF34C759) : Colors.white54,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  ws.isListening ? "Listening" : "Ready",
                                  style: GoogleFonts.inter(
                                    color: ws.isListening ? const Color(0xFF34C759) : Colors.white54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Feature 1: Context Selector Chips
                Container(
                  height: 38,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _contexts.length,
                    itemBuilder: (context, index) {
                      final item = _contexts[index];
                      final isSelected = ws.selectedContext == item;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: ChoiceChip(
                          label: Text(
                            item,
                            style: GoogleFonts.inter(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.white,
                          backgroundColor: const Color(0xFF161616),
                          checkmarkColor: Colors.black,
                          onSelected: (selected) {
                            if (selected) {
                              ws.selectedContext = item;
                              if (ws.transcript != "...") {
                                ws.sendText(ws.transcript);
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Main Content Scroll view
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      children: [
                        // Live Waveform Visualizer
                        AnimatedBuilder(
                          animation: _waveformController,
                          builder: (context, child) {
                            return SizedBox(
                              height: 50,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(24, (index) {
                                  double height = ws.isListening
                                      ? 8 + (sin((index + _waveformController.value * 12)) * 20).abs() + Random().nextDouble() * 5
                                      : 3;
                                  return Container(
                                    width: 2.5,
                                    height: height,
                                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                    decoration: BoxDecoration(
                                      color: ws.isListening
                                          ? Colors.white.withOpacity(0.8)
                                          : Colors.white24,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Feature 2: Real-time Scores Cards (Anxiety, Confidence, Clarity)
                        Row(
                          children: [
                            Expanded(child: _buildMetricMiniMeter("Anxiety", ws.anxiety, const Color(0xFFFF3B30))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricMiniMeter("Confidence", ws.confidence, const Color(0xFF34C759))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricMiniMeter("Clarity", ws.clarity, const Color(0xFF0A84FF))),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Chat Persona responses if active
                        if (ws.selectedPersona.isNotEmpty && ws.personaReply.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0F12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFBF5AF2).withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.sparkles, color: Color(0xFFBF5AF2), size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${ws.selectedPersona.toUpperCase()} RESPONSE",
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFBF5AF2),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  ws.personaReply,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Feature 3: Rewrite Engine Card
                        if (ws.improved.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E0E10),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.replace, color: Colors.amber, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          "REWRITE ENGINE",
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.amber,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.copy, color: Colors.white38, size: 14),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: ws.improved));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Improved version copied to clipboard"),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                    )
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Original Message:",
                                  style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ws.transcript,
                                  style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 13, decoration: TextDecoration.lineThrough),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Improved Version:",
                                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF34C759), fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "\"${ws.improved}\"",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Words Transcript Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.activity, color: Colors.white30, size: 11),
                                  const SizedBox(width: 6),
                                  Text(
                                    "YOUR TRANSCRIPT",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white30,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "\"${ws.transcript}\"",
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFFF5F5F7),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Feature 4: Live Coaching Recommendations Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: const Icon(LucideIcons.brainCircuit, color: Colors.white70, size: 14),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "COACH SUGGESTIONS",
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white30,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildPill(ws.emotion, Colors.white60),
                                        const SizedBox(width: 6),
                                        if (ws.pace != "N/A" && ws.pace != "0 wpm") ...[
                                          _buildPill(ws.pace, Colors.white30),
                                          const SizedBox(width: 6),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ws.suggestion,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (ws.coachingTips.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        "LIVE PROMPTS:",
                                        style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: ws.coachingTips.map((tip) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.04),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(LucideIcons.sparkles, color: Colors.cyanAccent, size: 10),
                                                const SizedBox(width: 4),
                                                Text(
                                                  tip,
                                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ]
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Control panel (Chat Typing Input + Mic toggle)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Chat Input
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    focusNode: _focusNode,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14.5),
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    decoration: InputDecoration(
                                      hintText: "Message...",
                                      hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14.5),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    onSubmitted: (val) {
                                      if (val.trim().isNotEmpty) {
                                        ws.mode = "chat";
                                        ws.sendText(val);
                                        _textController.clear();
                                      }
                                    },
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (_textController.text.trim().isNotEmpty) {
                                      ws.mode = "chat";
                                      ws.sendText(_textController.text);
                                      _textController.clear();
                                      _focusNode.unfocus();
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LucideIcons.arrowUp, color: Colors.white, size: 15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        
                        // Mic Toggle (Feature 6: Voice Mode Activation)
                        GestureDetector(
                          onTap: ws.toggleListening,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ws.isListening ? Colors.white : const Color(0xFF1C1C1E),
                              border: Border.all(
                                color: ws.isListening ? Colors.white : Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Icon(
                              ws.isListening ? LucideIcons.square : LucideIcons.mic,
                              color: ws.isListening ? Colors.black : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricMiniMeter(String title, String value, Color color) {
    // Extract integer percentage from value
    int pct = int.tryParse(value.replaceAll('%', '')) ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.03), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white30,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: pct / 100.0,
              backgroundColor: Colors.white.withOpacity(0.02),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: color.withOpacity(0.12), width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
