import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onBackground = Theme.of(context).colorScheme.onBackground;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SPEECH INSIGHTS",
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Your Progress",
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "LAST 7 DAYS",
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Main Chart Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TONE CONSISTENCY",
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "89.4 / 100",
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildDotLegend(context, "Clarity", Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
                        const SizedBox(width: 12),
                        _buildDotLegend(context, "Variation", Theme.of(context).colorScheme.onBackground.withOpacity(0.24)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: LineChartPainter(onBackgroundColor: onBackground),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                    return Text(
                      days[index],
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Side-by-side stats
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  "Pause Frequency",
                  "2.1 / min",
                  LucideIcons.hourglass,
                  "Excellent range",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  "Volume Level",
                  "72.4 dB",
                  LucideIcons.volume2,
                  "Clear and calm",
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pacing chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SPEECH PACING CONSISTENCY",
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: BarChartPainter(onBackgroundColor: onBackground),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ["Session 1", "Session 2", "Session 3", "Session 4", "Session 5"].map((text) {
                    return Text(
                      text,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Coach Insights
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "COACH INSIGHTS",
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInsightRow(
                  context,
                  "Filler Words",
                  "-40%",
                  "Excellent improvement — filler words are down to 0.4 per minute.",
                  LucideIcons.minusCircle,
                ),
                Divider(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), height: 28),
                _buildInsightRow(
                  context,
                  "Pacing Match",
                  "88%",
                  "You are maintaining a calm, balanced pace throughout your sessions.",
                  LucideIcons.gitCommit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDotLegend(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, String status) {
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
              Icon(icon, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4), size: 14),
              Icon(LucideIcons.trendingDown, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.24), size: 10),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            status,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(BuildContext context, String title, String stat, String desc, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08)),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7), size: 12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    stat,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LineChartPainter extends CustomPainter {
  final Color onBackgroundColor;

  LineChartPainter({required this.onBackgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = onBackgroundColor.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      double y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), borderPaint);
    }

    final p1 = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.16, size.height * 0.4),
      Offset(size.width * 0.33, size.height * 0.5),
      Offset(size.width * 0.5, size.height * 0.25),
      Offset(size.width * 0.66, size.height * 0.45),
      Offset(size.width * 0.83, size.height * 0.3),
      Offset(size.width, size.height * 0.2),
    ];

    final p2 = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.16, size.height * 0.6),
      Offset(size.width * 0.33, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.66, size.height * 0.65),
      Offset(size.width * 0.83, size.height * 0.55),
      Offset(size.width, size.height * 0.4),
    ];

    _drawSmoothLine(canvas, size, p1, onBackgroundColor.withOpacity(0.7), true);
    _drawSmoothLine(canvas, size, p2, onBackgroundColor.withOpacity(0.12), false);
  }

  void _drawSmoothLine(Canvas canvas, Size size, List<Offset> points, Color color, bool drawDots) {
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, linePaint);

    if (drawDots) {
      final dotPaint = Paint()
        ..color = onBackgroundColor
        ..style = PaintingStyle.fill;

      for (var pt in points) {
        canvas.drawCircle(pt, 2.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BarChartPainter extends CustomPainter {
  final Color onBackgroundColor;

  BarChartPainter({required this.onBackgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final barValues = [0.8, 0.95, 0.72, 0.88, 0.92];
    double widthPerBar = size.width / 5;
    double barWidth = 6;

    final basePaint = Paint()
      ..color = onBackgroundColor.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      double centerX = widthPerBar * i + widthPerBar / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, size.height / 2),
            width: barWidth,
            height: size.height,
          ),
          const Radius.circular(3),
        ),
        basePaint,
      );

      double barHeight = size.height * barValues[i];
      final valPaint = Paint()
        ..color = onBackgroundColor.withOpacity(0.5);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX - barWidth / 2,
            size.height - barHeight,
            barWidth,
            barHeight,
          ),
          const Radius.circular(3),
        ),
        valPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
