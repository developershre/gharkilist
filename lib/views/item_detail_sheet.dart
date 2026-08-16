import 'dart:io';
import '../widgets/item_icon_widget.dart';
import 'package:flutter/material.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';
import '../services/localization_service.dart';

class ItemDetailSheet extends StatefulWidget {
  final CatalogItem catalogItem;
  final int inventoryId;
  final String? capturedPhotoPath;
  final AppLanguage language;
  final Function(InventoryItem item) onSave;

  const ItemDetailSheet({
    super.key,
    required this.catalogItem,
    this.inventoryId = 1,
    this.capturedPhotoPath,
    this.language = AppLanguage.english,
    required this.onSave,
  });

  @override
  State<ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<ItemDetailSheet> {
  late TextEditingController _customNameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    final displayName = LocalizationService.getItemName(
      widget.catalogItem.nameEn,
      widget.catalogItem.nameHi,
      widget.language,
    );
    _customNameController = TextEditingController(text: displayName);
    _quantityController = TextEditingController(text: '1');
    _priceController = TextEditingController();
    _selectedUnit = widget.catalogItem.defaultUnit;
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final qty = double.tryParse(_quantityController.text) ?? 1.0;
    final price = double.tryParse(_priceController.text);
    final customName = _customNameController.text.trim();

    final item = InventoryItem(
      inventoryId: widget.inventoryId,
      catalogId: widget.catalogItem.id,
      customName: customName.isNotEmpty ? customName : widget.catalogItem.nameEn,
      nameHi: widget.catalogItem.nameHi,
      category: widget.catalogItem.category,
      quantity: qty,
      unit: _selectedUnit,
      estimatedPrice: price,
      capturedPhotoPath: widget.capturedPhotoPath,
      catalogItem: widget.catalogItem,
    );

    widget.onSave(item);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final hintColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final handleColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    final cleanTitle = widget.catalogItem.nameEn.replaceAll(RegExp(r'\s*\([^)]*\)'), '');

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle Indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Item Info
            Row(
              children: [
                ItemIconWidget(
                  itemId: widget.catalogItem.id,
                  category: widget.catalogItem.category,
                  emojiHint: widget.catalogItem.iconEmoji,
                  size: 64,
                  iconSize: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleanTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.catalogItem.category,
                        style: const TextStyle(
                          color: Color(0xFF00C853),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (widget.capturedPhotoPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.capturedPhotoPath!),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Item Name Field
            Text(
              'Item Name',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _customNameController,
              style: TextStyle(color: textColor, fontSize: 16),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quantity & Unit side by side
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _quantityController,
                        style: TextStyle(color: textColor, fontSize: 16),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        dropdownColor: cardBg,
                        initialValue: _selectedUnit.toUpperCase(),
                        style: TextStyle(color: textColor, fontSize: 16),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        items: ['KG', 'G', 'L', 'ML', 'PCS', 'PKT'].map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(u, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUnit = val.toLowerCase());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Estimated Prize (Optional) Field with Rs Suffix
            Text(
              'Estimated Prize (Optional)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _priceController,
              style: TextStyle(color: textColor, fontSize: 16),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'eg. 120',
                hintStyle: TextStyle(color: hintColor),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rs',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save to Inventory Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _handleSave,
                child: const Text(
                  'Save to Inventory',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
