import 'package:flutter/material.dart';

class InventoryFilterSheet extends StatefulWidget {
  final String categoryFilter;
  final String stockFilter;
  final String sortOption;
  final Function(String cat, String stock, String sort) onApply;
  final VoidCallback onReset;

  const InventoryFilterSheet({
    super.key,
    required this.categoryFilter,
    required this.stockFilter,
    required this.sortOption,
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
    final activeColor = const Color(0xFF00C853);
    final chipTextColor = isDark ? Colors.white : const Color(0xFF1E293B);

    final sortOptions = [
      {'label': 'Default', 'icon': Icons.swap_vert},
      {'label': 'A - Z', 'icon': Icons.sort_by_alpha},
      {'label': 'Z - A', 'icon': Icons.sort_by_alpha},
      {'label': 'Qty: Low → High', 'icon': Icons.arrow_upward},
      {'label': 'Qty: High → Low', 'icon': Icons.arrow_downward},
      {'label': 'Price: High → Low', 'icon': Icons.attach_money},
    ];

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
                const Text(
                  'Filter & Sort Inventory',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    widget.onReset();
                    Navigator.pop(context);
                  },
                  child: const Text('Reset', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Sort By:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortOptions.map((opt) {
                final label = opt['label'] as String;
                final icon = opt['icon'] as IconData;
                final isSel = _selectedSort == label;
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
                      _selectedSort = label;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'Flour & Grains', 'Oils & Ghee', 'Spices & Masala', 'Dairy & Bakery', 'Snacks & Beverages', 'Household'].map((cat) {
                final isSel = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSel,
                  selectedColor: activeColor,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : chipTextColor,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Stock Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'Low Stock', 'Out of Stock'].map((stk) {
                final isSel = _selectedStock == stk;
                return ChoiceChip(
                  label: Text(stk),
                  selected: isSel,
                  selectedColor: activeColor,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : chipTextColor,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    setState(() => _selectedStock = stk);
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
                child: const Text('Apply Filter & Sort', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
