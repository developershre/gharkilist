import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';

class ItemDetailSheet extends StatefulWidget {
  final CatalogItem catalogItem;
  final String? capturedPhotoPath;
  final Function(InventoryItem item) onSave;

  const ItemDetailSheet({
    super.key,
    required this.catalogItem,
    this.capturedPhotoPath,
    required this.onSave,
  });

  @override
  State<ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<ItemDetailSheet> {
  late double _quantity;
  late String _unit;
  bool _isLow = false;
  bool _isOut = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _quantity = 1.0;
    _unit = widget.catalogItem.defaultUnit;
    _nameController = TextEditingController(text: widget.catalogItem.nameEn);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _increment() {
    setState(() {
      _quantity += (_unit == 'g' || _unit == 'ml') ? 100 : 1;
    });
  }

  void _decrement() {
    if (_quantity > 0.5) {
      setState(() {
        _quantity -= (_unit == 'g' || _unit == 'ml') ? 100 : 1;
        if (_quantity < 0) _quantity = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
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
              Text(
                widget.catalogItem.iconEmoji,
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.catalogItem.nameEn,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      widget.catalogItem.nameHi,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.capturedPhotoPath != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt, color: Colors.green, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Photo linked (building training dataset)',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text('Quantity & Unit', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _decrement,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        _quantity % 1 == 0
                            ? _quantity.toInt().toString()
                            : _quantity.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _increment,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: widget.catalogItem.allowedUnits.map((u) {
                    final isSelected = u == _unit;
                    return ChoiceChip(
                      label: Text(u),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _unit = u;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Stock Status', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  avatar: Icon(
                    Icons.warning_amber_rounded,
                    color: _isLow ? Colors.black : Colors.amber,
                    size: 18,
                  ),
                  label: const Text('Running Low'),
                  selected: _isLow,
                  selectedColor: Colors.amber,
                  onSelected: (val) {
                    setState(() {
                      _isLow = val;
                      if (val) _isOut = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilterChip(
                  avatar: Icon(
                    Icons.error_outline,
                    color: _isOut ? Colors.white : Colors.redAccent,
                    size: 18,
                  ),
                  label: const Text('Out of Stock'),
                  selected: _isOut,
                  selectedColor: Colors.redAccent,
                  onSelected: (val) {
                    setState(() {
                      _isOut = val;
                      if (val) _isLow = false;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ShadButton(
              onPressed: () {
                final item = InventoryItem(
                  catalogId: widget.catalogItem.id,
                  customName: widget.catalogItem.nameEn,
                  nameHi: widget.catalogItem.nameHi,
                  category: widget.catalogItem.category,
                  quantity: _quantity,
                  unit: _unit,
                  isLow: _isLow,
                  isOut: _isOut,
                  capturedPhotoPath: widget.capturedPhotoPath,
                  catalogItem: widget.catalogItem,
                );
                widget.onSave(item);
                Navigator.pop(context);
              },
              child: const Text('Save to Pantry Inventory'),
            ),
          ),
        ],
      ),
    );
  }
}
