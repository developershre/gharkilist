import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import 'item_icon_widget.dart';

class InventoryItemTile extends StatelessWidget {
  final int index;
  final InventoryItem item;
  final VoidCallback onTap;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onQuantityTap;
  final ValueChanged<String> onUnitChanged;
  final VoidCallback onDeleteTap;

  const InventoryItemTile({
    super.key,
    required this.index,
    required this.item,
    required this.onTap,
    required this.onQuantityChanged,
    required this.onQuantityTap,
    required this.onUnitChanged,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryGreen = const Color(0xFF00C853);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drag Handle
          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.drag_indicator,
                color: subtextColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Product Image Asset / Icon
          GestureDetector(
            onTap: onTap,
            child: ItemIconWidget(
              itemId: item.catalogId,
              category: item.category,
              emojiHint: item.catalogItem?.iconEmoji,
              capturedPhotoPath: item.capturedPhotoPath,
              size: 58,
              iconSize: 30,
            ),
          ),
          const SizedBox(width: 14),

          // Middle Column: Title & Stepper Controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    item.customName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        if (item.quantity > 1) {
                          onQuantityChanged(item.quantity - 1);
                        } else {
                          onDeleteTap();
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.remove, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onQuantityTap,
                      child: Container(
                        width: 48,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: textColor, width: 1.2),
                        ),
                        child: Text(
                          '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => onQuantityChanged(item.quantity + 1),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right: Unit Dropdown Pill Button
          PopupMenuButton<String>(
            onSelected: onUnitChanged,
            itemBuilder: (context) => [
              'KG', 'G', 'L', 'ML', 'PCS', 'PKT'
            ].map((u) => PopupMenuItem(value: u, child: Text(u))).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.unit.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
