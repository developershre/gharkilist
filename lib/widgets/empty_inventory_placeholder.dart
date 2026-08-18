import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class EmptyInventoryPlaceholder extends StatelessWidget {
  final String listName;
  final AppLanguage language;
  final VoidCallback onAddItemTap;

  const EmptyInventoryPlaceholder({
    super.key,
    required this.listName,
    required this.language,
    required this.onAddItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final displayListName = LocalizationService.getListName(listName, language);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_shopping_cart_outlined,
                color: Color(0xFF00C853),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              language == AppLanguage.hindi
                  ? '"$displayListName" में कोई सामान नहीं है'
                  : 'No items in "$displayListName"',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              language == AppLanguage.hindi
                  ? 'सामान जोड़ने के लिए नीचे दिए गए बटन पर टैप करें'
                  : 'Tap below to scan or add items to this list',
              style: TextStyle(fontSize: 13, color: subtextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onAddItemTap,
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                language == AppLanguage.hindi ? 'सामान जोड़ें' : 'Add Item',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashedRectBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  DashedRectBorderPainter({
    this.color = const Color(0xFF000000),
    this.strokeWidth = 1.5,
    this.dash = 5.0,
    this.gap = 4.0,
    this.radius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + dash < metric.length)
            ? dash
            : metric.length - distance;
        canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        distance += len + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
