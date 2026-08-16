import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../services/localization_service.dart';
import 'item_icon_widget.dart';

class InventoryItemTile extends StatelessWidget {
  final int index;
  final InventoryItem item;
  final AppLanguage language;
  final VoidCallback onTap;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onQuantityTap;
  final ValueChanged<String> onUnitChanged;
  final VoidCallback onDeleteTap;

  const InventoryItemTile({
    super.key,
    required this.index,
    required this.item,
    this.language = AppLanguage.english,
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
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFF334155).withValues(alpha: 0.2);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final primaryGreen = const Color(0xFF008744);
    final deleteRed = const Color(0xFFC62828);

    final displayName = item.catalogItem != null
        ? LocalizationService.getItemName(
            item.catalogItem!.nameEn,
            item.catalogItem!.nameHi,
            language,
          )
        : LocalizationService.getItemName(
            item.customName,
            item.nameHi,
            language,
          );

    final qtyDisplay = item.quantity % 1 == 0
        ? item.quantity.toInt().toString()
        : item.quantity.toString();
    final unitDisplay = LocalizationService.getUnitLabel(item.unit, language);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // 6-dot Drag Handle
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Icon(
                    Icons.drag_indicator,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Item Image / Icon
              ItemIconWidget(
                itemId: item.catalogId,
                category: item.category,
                emojiHint: item.catalogItem?.iconEmoji,
                capturedPhotoPath: item.capturedPhotoPath,
                size: 58,
                iconSize: 30,
              ),
              const SizedBox(width: 16),

              // Middle Title & Quantity Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onQuantityTap,
                      child: Text(
                        '$qtyDisplay $unitDisplay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: subtextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Right Action Buttons: Green Edit & Red Delete
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_square,
                      color: primaryGreen,
                      size: 26,
                    ),
                    tooltip: language == AppLanguage.hindi ? 'संपादित करें' : 'Edit Item',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: onTap,
                  ),

                  const SizedBox(width: 6),

                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: deleteRed,
                      size: 26,
                    ),
                    tooltip: language == AppLanguage.hindi ? 'हटाएं' : 'Delete Item',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: onDeleteTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
