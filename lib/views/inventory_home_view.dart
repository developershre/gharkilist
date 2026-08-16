import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_item.dart';
import '../models/inventory_list.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import '../services/share_service.dart';
import '../widgets/item_icon_widget.dart';
import 'item_detail_sheet.dart';

class InventoryHomeView extends StatefulWidget {
  final InventoryList activeList;
  final List<InventoryItem> items;
  final AppLanguage language;
  final VoidCallback onRefresh;
  final Function(InventoryList newList) onListChanged;
  final VoidCallback onAddScanTap;
  final VoidCallback onAddBrowseTap;

  const InventoryHomeView({
    super.key,
    required this.activeList,
    required this.items,
    required this.language,
    required this.onRefresh,
    required this.onListChanged,
    required this.onAddScanTap,
    required this.onAddBrowseTap,
  });

  @override
  State<InventoryHomeView> createState() => _InventoryHomeViewState();
}

class _InventoryHomeViewState extends State<InventoryHomeView> {
  final TextEditingController _searchController = TextEditingController();
  late List<InventoryItem> _localItems;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _localItems = List.from(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InventoryHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _localItems = List.from(widget.items);
    }
  }

  String _selectedCategoryFilter = 'All';
  String _selectedStockFilter = 'All';
  String _selectedSortOption = 'Default';

  void _applySortOption(String sortOpt) {
    _selectedSortOption = sortOpt;
    if (sortOpt == 'A - Z') {
      _localItems.sort((a, b) => a.customName.toLowerCase().compareTo(b.customName.toLowerCase()));
    } else if (sortOpt == 'Z - A') {
      _localItems.sort((a, b) => b.customName.toLowerCase().compareTo(a.customName.toLowerCase()));
    } else if (sortOpt == 'Qty: Low → High') {
      _localItems.sort((a, b) => a.quantity.compareTo(b.quantity));
    } else if (sortOpt == 'Qty: High → Low') {
      _localItems.sort((a, b) => b.quantity.compareTo(a.quantity));
    } else if (sortOpt == 'Price: High → Low') {
      _localItems.sort((a, b) => (b.estimatedPrice ?? 0).compareTo(a.estimatedPrice ?? 0));
    }
    if (sortOpt != 'Default') {
      DatabaseHelper.instance.updateItemsDisplayOrder(_localItems);
    }
  }

  List<InventoryItem> get _filteredItems {
    Iterable<InventoryItem> list = _localItems;

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((i) =>
        i.customName.toLowerCase().contains(q) ||
        i.nameHi.toLowerCase().contains(q) ||
        i.category.toLowerCase().contains(q)
      );
    }

    if (_selectedCategoryFilter != 'All') {
      list = list.where((i) => i.category == _selectedCategoryFilter);
    }

    if (_selectedStockFilter == 'Low Stock') {
      list = list.where((i) => i.quantity > 0 && i.quantity <= 2);
    } else if (_selectedStockFilter == 'Out of Stock') {
      list = list.where((i) => i.quantity == 0);
    }

    return list.toList();
  }

  void _showFilterOptionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                            setModalState(() {
                              _selectedCategoryFilter = 'All';
                              _selectedStockFilter = 'All';
                              _selectedSortOption = 'Default';
                            });
                            setState(() {
                              _selectedCategoryFilter = 'All';
                              _selectedStockFilter = 'All';
                              _applySortOption('Default');
                            });
                            Navigator.pop(ctx);
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
                        final isSel = _selectedSortOption == label;
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
                            setModalState(() {
                              _selectedSortOption = label;
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
                        final isSel = _selectedCategoryFilter == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          selectedColor: activeColor,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : chipTextColor,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            setModalState(() => _selectedCategoryFilter = cat);
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
                        final isSel = _selectedStockFilter == stk;
                        return ChoiceChip(
                          label: Text(stk),
                          selected: isSel,
                          selectedColor: activeColor,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : chipTextColor,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            setModalState(() => _selectedStockFilter = stk);
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
                          setState(() {
                            _applySortOption(_selectedSortOption);
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply Filter & Sort', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onReorderItems(int oldIndex, int newIndex) async {
    setState(() {
      _selectedSortOption = 'Default';
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _localItems.removeAt(oldIndex);
      _localItems.insert(newIndex, item);
    });

    await DatabaseHelper.instance.updateItemsDisplayOrder(_localItems);
    widget.onRefresh();
  }

  double get _totalEstBudget {
    double total = 0.0;
    for (final i in _localItems) {
      if (i.estimatedPrice != null && i.estimatedPrice! > 0) {
        total += i.quantity * i.estimatedPrice!;
      }
    }
    return total;
  }

  void _showCreateListModal() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Inventory List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF000000)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Festival Ration, Monthly Pooja',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      final newList = await DatabaseHelper.instance.createInventory(name, '📦');
                      if (ctx.mounted) Navigator.pop(ctx);
                      widget.onListChanged(newList);
                    }
                  },
                  child: const Text('Create List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditQuantityDialog(InventoryItem item) {
    final controller = TextEditingController(
      text: item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Quantity for ${item.customName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Enter Quantity',
                  suffixText: item.unit.toUpperCase(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final val = double.tryParse(controller.text.trim());
                if (val != null && val > 0 && item.id != null) {
                  final updated = item.copyWith(quantity: val);
                  await DatabaseHelper.instance.updateInventoryItem(updated);
                  widget.onRefresh();
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(InventoryItem item) async {
    if (item.id != null) {
      await DatabaseHelper.instance.deleteInventoryItem(item.id!);
      widget.onRefresh();
    }
  }

  void _editItem(InventoryItem item) {
    if (item.catalogItem == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemDetailSheet(
        catalogItem: item.catalogItem!,
        capturedPhotoPath: item.capturedPhotoPath,
        language: widget.language,
        onSave: (updated) async {
          final updatedWithId = updated.copyWith(id: item.id, inventoryId: item.inventoryId);
          await DatabaseHelper.instance.updateInventoryItem(updatedWithId);
          widget.onRefresh();
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showAddModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Item to Kitchen',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.onAddScanTap();
                },
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA7F3D0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xFF000000),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan Photo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Take or scan images of the product',
                            style: TextStyle(
                              fontSize: 14,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Divider(color: dividerColor, thickness: 1),
              const SizedBox(height: 18),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.onAddBrowseTap();
                },
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA7F3D0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Color(0xFF000000),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Browse Collection',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Browse our collection of 400+ products',
                            style: TextStyle(
                              fontSize: 14,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final inputBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final currentListName = widget.activeList.name;
    final displayItems = _filteredItems;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: inputBorderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: subtextColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor, fontSize: 16),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: subtextColor, fontSize: 16),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _showFilterOptionsModal,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.tune,
                            color: (_selectedCategoryFilter != 'All' || _selectedStockFilter != 'All' || _selectedSortOption != 'Default')
                                ? const Color(0xFF00C853)
                                : subtextColor,
                            size: 22,
                          ),
                          if (_selectedCategoryFilter != 'All' || _selectedStockFilter != 'All' || _selectedSortOption != 'Default')
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00C853),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tag Pills Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTagPill('Mahine ka', 1, currentListName),
                  const SizedBox(width: 8),
                  _buildTagPill('Rakhi ka', 2, currentListName),
                  const SizedBox(width: 8),
                  _buildTagPill('Diwali ka', 3, currentListName),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showCreateListModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00C853)),
                      ),
                      child: const Text(
                        '+ New',
                        style: TextStyle(
                          color: Color(0xFF00C853),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_totalEstBudget > 0) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${displayItems.length} items',
                        style: TextStyle(color: subtextColor, fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Est. Budget: ₹${_totalEstBudget.toInt()}',
                        style: const TextStyle(
                          color: Color(0xFF00C853),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Reorderable List
          Expanded(
            child: displayItems.isEmpty
                ? Center(
                    child: Text(
                      'No items in list',
                      style: TextStyle(color: subtextColor, fontSize: 16),
                    ),
                  )
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: displayItems.length,
                    onReorderItem: _onReorderItems,
                    itemBuilder: (context, index) {
                      final item = displayItems[index];
                      final itemKey = ValueKey(item.id ?? item.catalogId);
                      final displayName = item.customName;

                      return Container(
                        key: itemKey,
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
                            // Drag Handle (6 dots icon) with explicit ReorderableDragStartListener
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
                              onTap: () => _editItem(item),
                              child: ItemIconWidget(
                                itemId: item.catalogId,
                                category: item.category,
                                emojiHint: item.catalogItem?.iconEmoji,
                                size: 58,
                                iconSize: 30,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Middle Column: Item Title (Top) & Stepper Controls (Bottom)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => _editItem(item),
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Stepper Controls [-] [ 1 ] [+]
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                          if (item.id != null) {
                                            if (item.quantity > 1) {
                                              final updated = item.copyWith(quantity: item.quantity - 1);
                                              await DatabaseHelper.instance.updateInventoryItem(updated);
                                              widget.onRefresh();
                                            } else {
                                              _deleteItem(item);
                                            }
                                          }
                                        },
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00C853),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.remove, color: Colors.white, size: 18),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => _showEditQuantityDialog(item),
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
                                        onTap: () async {
                                          if (item.id != null) {
                                            final updated = item.copyWith(quantity: item.quantity + 1);
                                            await DatabaseHelper.instance.updateInventoryItem(updated);
                                            widget.onRefresh();
                                          }
                                        },
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00C853),
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

                            // Right: Unit Dropdown Pill Button [ KG v ]
                            PopupMenuButton<String>(
                              onSelected: (newUnit) async {
                                if (item.id != null) {
                                  final updated = item.copyWith(unit: newUnit);
                                  await DatabaseHelper.instance.updateInventoryItem(updated);
                                  widget.onRefresh();
                                }
                              },
                              itemBuilder: (context) => [
                                'KG', 'G', 'L', 'ML', 'PCS', 'PKT'
                              ].map((u) => PopupMenuItem(value: u, child: Text(u))).toList(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C853),
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
                    },
                  ),
          ),

          // Bottom Action Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ShadButton(
                    height: 52,
                    backgroundColor: const Color(0xFF00C853),
                    onPressed: () => ShareService.shareToWhatsApp(
                      widget.items,
                      listName: widget.activeList.name,
                      language: widget.language,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "Share On What's App",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ShadButton.raw(
                  variant: ShadButtonVariant.primary,
                  width: 52,
                  height: 52,
                  padding: EdgeInsets.zero,
                  backgroundColor: const Color(0xFF00C853),
                  onPressed: () => _showAddModal(context),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagPill(String name, int id, String currentListName) {
    final isSelected = currentListName.toLowerCase() == name.toLowerCase();

    if (isSelected) {
      return ShadBadge(
        backgroundColor: const Color(0xFF00C853),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    return ShadButton.ghost(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      onPressed: () {
        widget.onListChanged(
          InventoryList(id: id, name: name, iconEmoji: '📦'),
        );
      },
      child: Text(
        name,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFCBD5E1)
              : const Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

