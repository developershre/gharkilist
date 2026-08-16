import 'package:flutter/material.dart';
import '../main.dart';
import '../services/localization_service.dart';

class GharkiListLogoWidget extends StatelessWidget {
  final double fontSize;
  final double iconSize;
  final AppLanguage? language;

  const GharkiListLogoWidget({
    super.key,
    this.fontSize = 22,
    this.iconSize = 28,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gharkiColor = isDark ? Colors.white : const Color(0xFF1E293B);

    AppLanguage currentLang = language ?? AppLanguage.english;
    try {
      currentLang = language ?? GharkilistApp.of(context).language;
    } catch (_) {}

    final isHindi = currentLang == AppLanguage.hindi;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: iconSize,
          height: iconSize,
          child: CustomPaint(
            painter: _HouseLogoPainter(isDark: isDark),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: isHindi ? 'घरकी' : 'gharki',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: gharkiColor,
                  letterSpacing: isHindi ? 0 : -0.5,
                ),
              ),
              TextSpan(
                text: isHindi ? 'लिस्ट' : 'list',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF00C853),
                  letterSpacing: isHindi ? 0 : -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HouseLogoPainter extends CustomPainter {
  final bool isDark;

  _HouseLogoPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final housePaint = Paint()
      ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(w * 0.15, h * 0.45);
    path.lineTo(w * 0.5, h * 0.15);
    path.lineTo(w * 0.85, h * 0.45);
    path.lineTo(w * 0.85, h * 0.9);
    path.lineTo(w * 0.15, h * 0.9);
    path.close();

    canvas.drawPath(path, housePaint);

    final boxPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        w * 0.28, h * 0.62, w * 0.48, h * 0.84,
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
      ),
      boxPaint,
    );

    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        w * 0.52, h * 0.52, w * 0.72, h * 0.84,
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
      ),
      boxPaint,
    );

    final checkPaint = Paint()
      ..color = const Color(0xFF00C853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path();
    checkPath.moveTo(w * 0.35, h * 0.32);
    checkPath.lineTo(w * 0.52, h * 0.45);
    checkPath.lineTo(w * 0.8, h * 0.18);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _HouseLogoPainter oldDelegate) => oldDelegate.isDark != isDark;
}
