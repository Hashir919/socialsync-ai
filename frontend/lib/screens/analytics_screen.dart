import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _logs = [];
  double _avgClarity = 85.0;
  double _avgConfidence = 70.0;
  double _avgAnxiety = 30.0;
  
  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final data = await _supabase
          .from('anxiety_logs')
          .select('anxiety, confidence, clarity, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: true)
          .limit(7);

      if (data != null && data.isNotEmpty) {
        final List<Map<String, dynamic>> fetchedLogs = List<Map<String, dynamic>>.from(data);
        
        double totalClarity = 0;
        double totalConfidence = 0;
        double totalAnxiety = 0;
        
        for (var log in fetchedLogs) {
          totalClarity += (log['clarity'] as num).toDouble();
          totalConfidence += (log['confidence'] as num).toDouble();
          totalAnxiety += (log['anxiety'] as num).toDouble();
        }
        
        setState(() {
          _logs = fetchedLogs;
          _avgClarity = totalClarity / fetchedLogs.length;
          _avgConfidence = totalConfidence / fetchedLogs.length;
          _avgAnxiety = totalAnxiety / fetchedLogs.length;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching analytics: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onBackground = Theme.of(context).colorScheme.onBackground;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchAnalyticsData,
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
                    _logs.isEmpty ? "OFFLINE DEMO" : "REAL-TIME SYNC",
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
                            "TONE CONSISTENCY (AVG CONFIDENCE)",
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${_avgConfidence.toStringAsFixed(1)} / 100",
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
                          _buildDotLegend(context, "Clarity", Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 12),
                          _buildDotLegend(context, "Confidence", Theme.of(context).colorScheme.onBackground.withOpacity(0.4)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: LineChartPainter(
                        onBackgroundColor: onBackground,
                        logs: _logs,
                        clarityColor: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                      if (_logs.isNotEmpty && index < _logs.length) {
                        try {
                          final date = DateTime.parse(_logs[index]['created_at']);
                          final weekdayMap = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                          return Text(
                            weekdayMap[date.weekday - 1],
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        } catch (_) {}
                      }
                      return Text(
                        days[index],
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
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
                    "Average Anxiety",
                    "${_avgAnxiety.toStringAsFixed(1)}%",
                    LucideIcons.frown,
                    _avgAnxiety < 40 ? "Healthy low stress" : "Moderate anxiety level",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    "Average Clarity",
                    "${_avgClarity.toStringAsFixed(1)}%",
                    LucideIcons.sparkles,
                    _avgClarity > 75 ? "Highly coherent speech" : "Needs structured flow",
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
                    "CONVERSATIONAL LOG HISTORY",
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
                      painter: BarChartPainter(
                        onBackgroundColor: onBackground,
                        logs: _logs,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      return Text(
                        "Session ${index + 1}",
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }),
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
                    "Anxiety Control",
                    _avgAnxiety < 30 ? "Optimal" : "Needs practice",
                    "Your average social sync anxiety level is at ${_avgAnxiety.toStringAsFixed(1)}%. Keep roleplaying to build confidence.",
                    LucideIcons.shield,
                  ),
                  Divider(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), height: 28),
                  _buildInsightRow(
                    context,
                    "Speech Coherence",
                    "${_avgClarity.toStringAsFixed(0)}%",
                    "You express thoughts with strong structuring and minimal rambling in your responses.",
                    LucideIcons.messageCircle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
              Icon(LucideIcons.trendingUp, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.24), size: 10),
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
  final List<Map<String, dynamic>> logs;
  final Color clarityColor;

  LineChartPainter({
    required this.onBackgroundColor,
    required this.logs,
    required this.clarityColor,
  });

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

    // Baseline fallback points if no logs are present
    List<Offset> clarityPoints = [];
    List<Offset> confidencePoints = [];

    if (logs.isEmpty) {
      final defaultClarity = [85.0, 78.0, 80.0, 89.0, 84.0, 88.0, 92.0];
      final defaultConfidence = [60.0, 65.0, 58.0, 70.0, 68.0, 75.0, 80.0];
      
      for (int i = 0; i < 7; i++) {
        double x = size.width * i / 6;
        clarityPoints.add(Offset(x, size.height * (100 - defaultClarity[i]) / 100));
        confidencePoints.add(Offset(x, size.height * (100 - defaultConfidence[i]) / 100));
      }
    } else {
      final double widthStep = logs.length > 1 ? size.width / (logs.length - 1) : size.width;
      for (int i = 0; i < logs.length; i++) {
        double x = widthStep * i;
        double clarity = (logs[i]['clarity'] as num).toDouble();
        double confidence = (logs[i]['confidence'] as num).toDouble();
        
        clarityPoints.add(Offset(x, size.height * (100 - clarity) / 100));
        confidencePoints.add(Offset(x, size.height * (100 - confidence) / 100));
      }
    }

    _drawSmoothLine(canvas, size, clarityPoints, clarityColor, true);
    _drawSmoothLine(canvas, size, confidencePoints, onBackgroundColor.withOpacity(0.15), false);
  }

  void _drawSmoothLine(Canvas canvas, Size size, List<Offset> points, Color color, bool drawDots) {
    if (points.isEmpty) return;
    
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
      ..strokeWidth = 2.0;

    canvas.drawPath(path, linePaint);

    if (drawDots) {
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (var pt in points) {
        canvas.drawCircle(pt, 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarChartPainter extends CustomPainter {
  final Color onBackgroundColor;
  final List<Map<String, dynamic>> logs;

  BarChartPainter({required this.onBackgroundColor, required this.logs});

  @override
  void paint(Canvas canvas, Size size) {
    final double defaultAnxietyRatio = 0.35;
    double widthPerBar = size.width / 5;
    double barWidth = 6.0;

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

      double anxietyRatio = defaultAnxietyRatio;
      if (logs.isNotEmpty && i < logs.length) {
        anxietyRatio = (logs[i]['anxiety'] as num).toDouble() / 100.0;
      }

      double barHeight = size.height * anxietyRatio;
      final valPaint = Paint()
        ..color = onBackgroundColor.withOpacity(0.4);

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
