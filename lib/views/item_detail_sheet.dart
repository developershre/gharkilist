import 'dart:io';
import 'package:flutter/material.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';
import '../models/inventory_list.dart';
import '../services/localization_service.dart';

class ItemDetailSheet extends StatefulWidget {
  final CatalogItem catalogItem;
  final List<InventoryItem> existingItemsAcrossLists;
  final List<InventoryList> allLists;
  final int activeInventoryId;
  final String? capturedPhotoPath;
  final AppLanguage language;
  final Function(
    String customName,
    String unit,
    double? price,
    Map<int, double> listQuantities,
  ) onSave;
  final VoidCallback? onDelete;

  const ItemDetailSheet({
    super.key,
    required this.catalogItem,
    required this.existingItemsAcrossLists,
    required this.allLists,
    this.activeInventoryId = 1,
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
  late TextEditingController _priceController;
  late String _selectedUnit;
  late Map<int, double> _selectedListsQuantities;

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
    final hasExisting = widget.existingItemsAcrossLists.isNotEmpty;
    final primaryExistingItem = hasExisting ? widget.existingItemsAcrossLists.first : null;

    final displayName = primaryExistingItem != null
        ? primaryExistingItem.customName
        : LocalizationService.getItemName(
            widget.catalogItem.nameEn,
            widget.catalogItem.nameHi,
            widget.language,
          );

    _customNameController = TextEditingController(text: displayName);
    final estPrice = primaryExistingItem?.estimatedPrice;
    _priceController = TextEditingController(
      text: estPrice != null
          ? (estPrice % 1 == 0 ? estPrice.toInt().toString() : estPrice.toString())
          : '',
    );
    _selectedUnit = primaryExistingItem?.unit ?? widget.catalogItem.defaultUnit;

    // Initialize list quantities
    _selectedListsQuantities = {};
    if (hasExisting) {
      for (final item in widget.existingItemsAcrossLists) {
        _selectedListsQuantities[item.inventoryId] = item.quantity;
      }
    } else {
      _selectedListsQuantities[widget.activeInventoryId] = 1.0;
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final price = double.tryParse(_priceController.text);
    final customName = _customNameController.text.trim();

    widget.onSave(
      customName.isNotEmpty ? customName : widget.catalogItem.nameEn,
      LocalizationService.normalizeUnit(_selectedUnit),
      price,
      _selectedListsQuantities,
    );
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

            // Unit Input (Global)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi ? 'इकाई (मात्रा का प्रकार)' : 'Unit (Type of Quantity)',
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

            // Select Lists & Quantities section
            Text(
              isHindi ? 'लिस्ट और मात्रा चुनें' : 'Select Lists & Quantities',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              ),
              padding: const EdgeInsets.all(12),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.allLists.length,
                separatorBuilder: (context, index) => Divider(color: borderColor, height: 16),
                itemBuilder: (context, index) {
                  final list = widget.allLists[index];
                  final listId = list.id ?? 0;
                  final isSelected = _selectedListsQuantities.containsKey(listId);
                  final qty = _selectedListsQuantities[listId] ?? 1.0;
                  final qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();

                  return Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        activeColor: const Color(0xFF00C853),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedListsQuantities[listId] = 1.0;
                            } else {
                              _selectedListsQuantities.remove(listId);
                            }
                          });
                        },
                      ),

                      Expanded(
                        child: Text(
                          list.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? textColor : subtextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) ...[
                        Container(
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor),
                            color: cardBg,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 14),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                onPressed: () {
                                  if (qty > 1) {
                                    setState(() {
                                      _selectedListsQuantities[listId] = qty - 1;
                                    });
                                  }
                                },
                              ),
                              SizedBox(
                                width: 36,
                                child: TextFormField(
                                  initialValue: qtyStr,
                                  key: ValueKey('qty_${listId}_$qtyStr'),
                                  textAlign: TextAlign.center,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (val) {
                                    final d = double.tryParse(val);
                                    if (d != null && d > 0) {
                                      _selectedListsQuantities[listId] = d;
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 14),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                onPressed: () {
                                  setState(() {
                                    _selectedListsQuantities[listId] = qty + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            LocalizationService.getUnitLabel(_selectedUnit, widget.language).toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: subtextColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
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
                onPressed: _selectedListsQuantities.isNotEmpty ? _handleSave : null,
                child: Text(
                  widget.existingItemsAcrossLists.isNotEmpty
                      ? (isHindi ? 'सामान अपडेट करें' : 'Update Inventory Item')
                      : (isHindi ? 'सूची में सहेजें' : 'Save to Inventory'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            if (widget.existingItemsAcrossLists.isNotEmpty && widget.onDelete != null) ...[
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
                              ? 'क्या आप इसे सभी लिस्ट से हटाना चाहते हैं?'
                              : 'Are you sure you want to remove this item from all your inventories?',
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
