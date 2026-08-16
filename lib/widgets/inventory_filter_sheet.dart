import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class InventoryFilterSheet extends StatefulWidget {
  final String categoryFilter;
  final String stockFilter;
  final String sortOption;
  final AppLanguage language;
  final Function(String cat, String stock, String sort) onApply;
  final VoidCallback onReset;

  const InventoryFilterSheet({
    super.key,
    required this.categoryFilter,
    required this.stockFilter,
    required this.sortOption,
    this.language = AppLanguage.english,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<InventoryFilterSheet> createState() => _InventoryFilterSheetState();
}

class _InventoryFilterSheetState extends State<InventoryFilterSheet> {
  late String _selectedCategory;
  late String _selectedStock;
  late String _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categoryFilter;
    _selectedStock = widget.stockFilter;
    _selectedSort = widget.sortOption;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHindi = widget.language == AppLanguage.hindi;
    final activeColor = const Color(0xFF00C853);
    final chipTextColor = isDark ? Colors.white : const Color(0xFF1E293B);

    final sortOptions = [
      {'key': 'Default', 'icon': Icons.swap_vert},
      {'key': 'A - Z', 'icon': Icons.sort_by_alpha},
      {'key': 'Z - A', 'icon': Icons.sort_by_alpha},
      {'key': 'Qty: Low → High', 'icon': Icons.arrow_upward},
      {'key': 'Qty: High → Low', 'icon': Icons.arrow_downward},
      {'key': 'Price: High → Low', 'icon': Icons.attach_money},
    ];

    final categories = [
      'All',
      'Flour & Grains',
      'Oils & Ghee',
      'Spices & Masala',
      'Dairy & Bakery',
      'Snacks & Beverages',
      'Household',
      'Pooja Essentials',
      'Other',
    ];

    final stockStatuses = ['All', 'Low Stock', 'Out of Stock'];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isHindi ? 'फ़िल्टर और सॉर्ट' : 'Filter & Sort Inventory',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    widget.onReset();
                    Navigator.pop(context);
                  },
                  child: Text(
                    isHindi ? 'रीसेट' : 'Reset',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isHindi ? 'सॉर्ट करें:' : 'Sort By:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortOptions.map((opt) {
                final key = opt['key'] as String;
                final icon = opt['icon'] as IconData;
                final label = LocalizationService.getSortOptionLabel(key, widget.language);
                final isSel = _selectedSort == key;
                return ChoiceChip(
                  avatar: Icon(icon, size: 16, color: isSel ? Colors.white : activeColor),
                  label: Text(label),
                  selected: isSel,
                  selectedColor: activeColor,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : chipTextColor,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    setState(() {
                      _selectedSort = key;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              isHindi ? 'श्रेणी (Category):' : 'Category:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((catKey) {
                final label = LocalizationService.getCategoryName(catKey, widget.language);
                final isSel = _selectedCategory == catKey;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSel,
                  selectedColor: activeColor,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : chipTextColor,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    setState(() => _selectedCategory = catKey);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              isHindi ? 'स्टॉक स्थिति:' : 'Stock Status:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stockStatuses.map((stkKey) {
                final label = LocalizationService.getStatusLabel(stkKey, widget.language);
                final isSel = _selectedStock == stkKey;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSel,
                  selectedColor: activeColor,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : chipTextColor,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    setState(() => _selectedStock = stkKey);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  widget.onApply(_selectedCategory, _selectedStock, _selectedSort);
                  Navigator.pop(context);
                },
                child: Text(
                  isHindi ? 'फ़िल्टर लागू करें' : 'Apply Filter & Sort',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
