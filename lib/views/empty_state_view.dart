import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/catalog_item.dart';
import '../models/inventory_list.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';

class EmptyStateView extends StatefulWidget {
  final InventoryList activeList;
  final AppLanguage language;
  final VoidCallback onScanTap;
  final VoidCallback onBrowseTap;
  final Function(CatalogItem item) onQuickAddCatalogItem;
  final Function(InventoryList newList)? onListChanged;

  const EmptyStateView({
    super.key,
    required this.activeList,
    required this.language,
    required this.onScanTap,
    required this.onBrowseTap,
    required this.onQuickAddCatalogItem,
    this.onListChanged,
  });

  @override
  State<EmptyStateView> createState() => _EmptyStateViewState();
}

class _EmptyStateViewState extends State<EmptyStateView> {
  final TextEditingController _searchController = TextEditingController();

  void _showAddOptionsModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Item to Kitchen',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.onScanTap();
                },
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA7F3D0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xFF000000),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan Photo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Take or scan images of the product',
                            style: TextStyle(
                              fontSize: 14,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Divider(color: dividerColor, thickness: 1),
              const SizedBox(height: 18),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.onBrowseTap();
                },
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA7F3D0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Color(0xFF000000),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Browse Collection',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Browse our collection of 400+ products',
                            style: TextStyle(
                              fontSize: 14,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCreateListModal() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Inventory List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF000000)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Festival Ration, Monthly Pooja',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      final newList = await DatabaseHelper.instance.createInventory(name, '📦');
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (widget.onListChanged != null) widget.onListChanged!(newList);
                    }
                  },
                  child: const Text('Create List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Tag Pills Row
  Widget _buildTagBar(String currentListName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTagPill('Mahine ka', 1, currentListName),
            const SizedBox(width: 8),
            _buildTagPill('Rakhi ka', 2, currentListName),
            const SizedBox(width: 8),
            _buildTagPill('Diwali ka', 3, currentListName),
            const SizedBox(width: 8),
            InkWell(
              onTap: _showCreateListModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00C853)),
                ),
                child: const Text(
                  '+ New',
                  style: TextStyle(
                    color: Color(0xFF00C853),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dashedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF000000);

    final currentListName = widget.activeList.name;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: subtextColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: subtextColor, fontSize: 16),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => widget.onBrowseTap(),
                    ),
                  ),
                  Icon(Icons.tune, color: subtextColor, size: 20),
                ],
              ),
            ),
          ),
          _buildTagBar(currentListName),
          const SizedBox(height: 16),

          // Dashed Add Item Box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () => _showAddOptionsModal(context),
              child: CustomPaint(
                painter: DashedRectBorderPainter(
                  color: dashedColor,
                  strokeWidth: 1.5,
                  dash: 5.0,
                  gap: 4.0,
                  radius: 12.0,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        color: textColor,
                        size: 48,
                      ),
                      const SizedBox(width: 24),
                      Text(
                        'Add new Item',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagPill(String name, int id, String currentListName) {
    final isSelected = currentListName.toLowerCase() == name.toLowerCase();

    if (isSelected) {
      return ShadBadge(
        backgroundColor: const Color(0xFF00C853),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    return ShadButton.ghost(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      onPressed: () {
        if (widget.onListChanged != null) {
          widget.onListChanged!(
            InventoryList(id: id, name: name, iconEmoji: '📦'),
          );
        }
      },
      child: Text(
        name,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFCBD5E1)
              : const Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
          fontSize: 14,
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
        final len = (distance + dash < metric.length) ? dash : metric.length - distance;
        canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        distance += len + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

