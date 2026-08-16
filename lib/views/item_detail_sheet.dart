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
  final VoidCallback? onDelete;
  final InventoryItem? existingItem;

  const ItemDetailSheet({
    super.key,
    required this.catalogItem,
    this.inventoryId = 1,
    this.capturedPhotoPath,
    this.language = AppLanguage.english,
    required this.onSave,
    this.onDelete,
    this.existingItem,
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
    final displayName = widget.existingItem?.customName ??
        LocalizationService.getItemName(
          widget.catalogItem.nameEn,
          widget.catalogItem.nameHi,
          widget.language,
        );
    _customNameController = TextEditingController(text: displayName);
    _quantityController = TextEditingController(
      text: widget.existingItem != null
          ? (widget.existingItem!.quantity % 1 == 0
              ? widget.existingItem!.quantity.toInt().toString()
              : widget.existingItem!.quantity.toString())
          : '1',
    );
    _priceController = TextEditingController(
      text: widget.existingItem?.estimatedPrice != null
          ? (widget.existingItem!.estimatedPrice! % 1 == 0
              ? widget.existingItem!.estimatedPrice!.toInt().toString()
              : widget.existingItem!.estimatedPrice!.toString())
          : '',
    );
    _selectedUnit = widget.existingItem?.unit ?? widget.catalogItem.defaultUnit;
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
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header Item Info with Close Button
            Row(
              children: [
                ItemIconWidget(
                  itemId: widget.catalogItem.id,
                  category: widget.catalogItem.category,
                  emojiHint: widget.catalogItem.iconEmoji,
                  size: 60,
                  iconSize: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleanTitle,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.catalogItem.category,
                        style: const TextStyle(
                          color: Color(0xFF00C853),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: hintColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

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

            // Quantity Stepper & Unit side by side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
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
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                final val = double.tryParse(_quantityController.text) ?? 1.0;
                                if (val > 1) {
                                  final newVal = val - 1;
                                  _quantityController.text =
                                      newVal % 1 == 0 ? newVal.toInt().toString() : newVal.toString();
                                  setState(() {});
                                }
                              },
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                              child: Container(
                                width: 38,
                                height: double.infinity,
                                alignment: Alignment.center,
                                child: Icon(Icons.remove, color: textColor, size: 18),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _quantityController,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                final val = double.tryParse(_quantityController.text) ?? 1.0;
                                final newVal = val + 1;
                                _quantityController.text =
                                    newVal % 1 == 0 ? newVal.toInt().toString() : newVal.toString();
                                setState(() {});
                              },
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                              child: Container(
                                width: 38,
                                height: double.infinity,
                                alignment: Alignment.center,
                                child: Icon(Icons.add, color: textColor, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
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
                        style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                            child: Text(u, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
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
                child: Text(
                  widget.existingItem != null ? 'Update Inventory Item' : 'Save to Inventory',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            if (widget.onDelete != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(widget.language == AppLanguage.hindi ? 'आइटम हटाएं?' : 'Delete Item?'),
                        content: Text(
                          widget.language == AppLanguage.hindi
                              ? 'क्या आप इसे लिस्ट से हटाना चाहते हैं?'
                              : 'Are you sure you want to remove this item from your inventory?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(widget.language == AppLanguage.hindi ? 'रद्द करें' : 'Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              widget.onDelete!();
                            },
                            child: Text(widget.language == AppLanguage.hindi ? 'हटाएं' : 'Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text(
                    widget.language == AppLanguage.hindi ? 'आइटम हटाएं' : 'Delete Item',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
