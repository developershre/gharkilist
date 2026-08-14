import 'dart:io';
import '../widgets/item_icon_widget.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';
import '../services/localization_service.dart';

class ItemDetailSheet extends StatefulWidget {
  final CatalogItem catalogItem;
  final String? capturedPhotoPath;
  final AppLanguage language;
  final Function(InventoryItem item) onSave;

  const ItemDetailSheet({
    super.key,
    required this.catalogItem,
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
      inventoryId: 1,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHindi = widget.language == AppLanguage.hindi;

    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final displayName = LocalizationService.getItemName(widget.catalogItem.nameEn, widget.catalogItem.nameHi, widget.language);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ItemIconWidget(
                itemId: widget.catalogItem.id,
                category: widget.catalogItem.category,
                emojiHint: widget.catalogItem.iconEmoji,
                size: 52,
                iconSize: 26,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      widget.catalogItem.category,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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

          Text(isHindi ? 'सामान का नाम' : 'Item Name', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ShadInput(
            controller: _customNameController,
            placeholder: Text(isHindi ? 'सामान का नाम दर्ज करें' : 'Enter custom item name'),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isHindi ? 'मात्रा' : 'Quantity', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ShadInput(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      placeholder: const Text('1'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isHindi ? 'इकाई (Unit)' : 'Unit', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                      items: widget.catalogItem.allowedUnits.map((u) {
                        return DropdownMenuItem(value: u, child: Text(u));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(isHindi ? 'अनुमानित कीमत (₹) (Optional)' : 'Estimated Price (₹) (Optional)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ShadInput(
            controller: _priceController,
            keyboardType: TextInputType.number,
            placeholder: const Text('e.g. 120'),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _handleSave,
              child: Text(
                isHindi ? 'सूची में जोड़ें' : 'Save to Inventory List',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
