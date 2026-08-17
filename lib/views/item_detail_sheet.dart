import 'dart:io';
import 'package:flutter/material.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';
import '../services/localization_service.dart';

class ItemDetailSheet extends StatefulWidget {
  final CatalogItem catalogItem;
  final InventoryItem? existingItem;
  final int inventoryId;
  final String? capturedPhotoPath;
  final AppLanguage language;
  final Function(InventoryItem item) onSave;
  final VoidCallback? onDelete;

  const ItemDetailSheet({
    super.key,
    required this.catalogItem,
    this.existingItem,
    this.inventoryId = 1,
    this.capturedPhotoPath,
    this.language = AppLanguage.english,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<ItemDetailSheet> {
  late TextEditingController _customNameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late String _selectedUnit;

  List<String> get _availableUnits {
    final set = <String>{};
    for (final u in widget.catalogItem.allowedUnits) {
      set.add(LocalizationService.normalizeUnit(u).toUpperCase());
    }
    set.add(LocalizationService.normalizeUnit(widget.catalogItem.defaultUnit).toUpperCase());
    if (_selectedUnit.isNotEmpty) {
      set.add(LocalizationService.normalizeUnit(_selectedUnit).toUpperCase());
    }
    set.addAll(['KG', 'G', 'L', 'ML', 'PCS', 'PKT', 'BOTTLE', 'CAN', 'BOX', 'STRIP', 'SACHET']);
    return set.toList();
  }

  @override
  void initState() {
    super.initState();
    final displayName = widget.existingItem != null
        ? widget.existingItem!.customName
        : LocalizationService.getItemName(
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
      id: widget.existingItem?.id,
      inventoryId: widget.inventoryId,
      catalogId: widget.catalogItem.id,
      customName: customName.isNotEmpty ? customName : widget.catalogItem.nameEn,
      nameHi: widget.existingItem?.nameHi ?? widget.catalogItem.nameHi,
      category: widget.catalogItem.category,
      quantity: qty,
      unit: LocalizationService.normalizeUnit(_selectedUnit),
      estimatedPrice: price,
      capturedPhotoPath: widget.capturedPhotoPath ?? widget.existingItem?.capturedPhotoPath,
      catalogItem: widget.catalogItem,
    );

    widget.onSave(item);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHindi = widget.language == AppLanguage.hindi;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final hintColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final cleanTitle = LocalizationService.getItemName(
      widget.catalogItem.nameEn,
      widget.catalogItem.nameHi,
      widget.language,
    );

    final categoryLabel = LocalizationService.getCategoryName(
      widget.catalogItem.category,
      widget.language,
      categoryHi: widget.catalogItem.categoryHi,
    );

    final activeUnits = _availableUnits;
    final normalizedSelected = LocalizationService.normalizeUnit(_selectedUnit).toUpperCase();
    final safeUnitValue = activeUnits.contains(normalizedSelected) ? normalizedSelected : activeUnits.first;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle & Title Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Item Name & Category Subtitle
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      const SizedBox(height: 2),
                      Text(
                        categoryLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: subtextColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Optional Captured Image Preview
            if (widget.capturedPhotoPath != null && File(widget.capturedPhotoPath!).existsSync()) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.capturedPhotoPath!),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Item Display Name Input Field
            Text(
              isHindi ? 'सामान का नाम' : 'Item Name',
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

            // Quantity & Unit Input Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quantity Stepper & Input
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi ? 'मात्रा' : 'Quantity',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: () {
                                final current = double.tryParse(_quantityController.text) ?? 1.0;
                                if (current > 1) {
                                  final next = current - 1;
                                  _quantityController.text = next % 1 == 0 ? next.toInt().toString() : next.toString();
                                }
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: _quantityController,
                                textAlign: TextAlign.center,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () {
                                final current = double.tryParse(_quantityController.text) ?? 1.0;
                                final next = current + 1;
                                _quantityController.text = next % 1 == 0 ? next.toInt().toString() : next.toString();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Unit Dropdown Selector
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi ? 'इकाई' : 'Unit',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        dropdownColor: cardBg,
                        initialValue: safeUnitValue,
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
                        items: activeUnits.map((u) {
                          final uLabel = LocalizationService.getUnitLabel(u.toLowerCase(), widget.language);
                          return DropdownMenuItem(
                            value: u,
                            child: Text(uLabel, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedUnit = LocalizationService.normalizeUnit(val.toLowerCase());
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Estimated Price Field
            Text(
              isHindi ? 'अनुमानित कीमत (वैकल्पिक)' : 'Estimated Price (Optional)',
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: isHindi ? 'उदा. 120' : 'e.g. 120',
                hintStyle: TextStyle(color: hintColor),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isHindi ? 'रु' : 'Rs',
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

            // Save / Update Button
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
                  widget.existingItem != null
                      ? (isHindi ? 'सामान अपडेट करें' : 'Update Inventory Item')
                      : (isHindi ? 'सूची में सहेजें' : 'Save to Inventory'),
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
                        title: Text(isHindi ? 'आइटम हटाएं?' : 'Delete Item?'),
                        content: Text(
                          isHindi
                              ? 'क्या आप इसे लिस्ट से हटाना चाहते हैं?'
                              : 'Are you sure you want to remove this item from your inventory?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
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
                            child: Text(isHindi ? 'हटाएं' : 'Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text(
                    isHindi ? 'आइटम हटाएं' : 'Delete Item',
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
