import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_item.dart';
import '../models/inventory_list.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import '../services/share_service.dart';
import '../widgets/add_item_options_sheet.dart';
import '../widgets/create_list_dialog.dart';
import '../widgets/empty_inventory_placeholder.dart';
import '../widgets/inventory_filter_sheet.dart';
import '../widgets/inventory_item_tile.dart';
import '../widgets/inventory_search_bar.dart';
import '../widgets/inventory_tag_bar.dart';
import 'add_item_form_view.dart';
import 'item_detail_sheet.dart';

class InventoryHomeView extends StatefulWidget {
  final InventoryList activeList;
  final List<InventoryList> allLists;
  final List<InventoryItem> items;
  final AppLanguage language;
  final VoidCallback onRefresh;
  final Function(InventoryList newList) onListChanged;
  final Function(InventoryList newList) onListCreated;
  final VoidCallback onAddScanTap;
  final VoidCallback onAddBrowseTap;

  const InventoryHomeView({
    super.key,
    required this.activeList,
    required this.allLists,
    required this.items,
    required this.language,
    required this.onRefresh,
    required this.onListChanged,
    required this.onListCreated,
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
  String _selectedCategoryFilter = 'All';
  String _selectedStockFilter = 'All';
  String _selectedSortOption = 'Default';

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
    if (oldWidget.items != widget.items || oldWidget.activeList.id != widget.activeList.id) {
      _localItems = List.from(widget.items);
    }
  }

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

  bool get _hasActiveFilters =>
      _selectedCategoryFilter != 'All' ||
      _selectedStockFilter != 'All' ||
      _selectedSortOption != 'Default';

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => InventoryFilterSheet(
        categoryFilter: _selectedCategoryFilter,
        stockFilter: _selectedStockFilter,
        sortOption: _selectedSortOption,
        onApply: (cat, stock, sort) {
          setState(() {
            _selectedCategoryFilter = cat;
            _selectedStockFilter = stock;
            _applySortOption(sort);
          });
        },
        onReset: () {
          setState(() {
            _selectedCategoryFilter = 'All';
            _selectedStockFilter = 'All';
            _applySortOption('Default');
          });
        },
      ),
    );
  }

  void _showCreateListDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CreateListDialog(
        isHindi: widget.language == AppLanguage.hindi,
        onCreate: (name) async {
          final newList = await DatabaseHelper.instance.createInventory(name, '');
          widget.onListCreated(newList);
        },
      ),
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
    if (item.id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.language == AppLanguage.hindi ? 'आइटम हटाएं?' : 'Delete Item?'),
        content: Text(
          widget.language == AppLanguage.hindi
              ? 'क्या आप "${item.customName}" को लिस्ट से हटाना चाहते हैं?'
              : 'Are you sure you want to remove "${item.customName}" from your inventory?',
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
            onPressed: () async {
              Navigator.pop(ctx);
              final deletedItem = item;
              await DatabaseHelper.instance.deleteInventoryItem(item.id!);
              widget.onRefresh();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.language == AppLanguage.hindi
                          ? '"${deletedItem.customName}" हटा दिया गया'
                          : '"${deletedItem.customName}" deleted',
                    ),
                    action: SnackBarAction(
                      label: widget.language == AppLanguage.hindi ? 'वापस लाएं' : 'Undo',
                      onPressed: () async {
                        await DatabaseHelper.instance.addInventoryItem(deletedItem);
                        widget.onRefresh();
                      },
                    ),
                  ),
                );
              }
            },
            child: Text(widget.language == AppLanguage.hindi ? 'हटाएं' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _editItem(InventoryItem item) {
    if (item.catalogItem == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemDetailSheet(
        catalogItem: item.catalogItem!,
        existingItem: item,
        capturedPhotoPath: item.capturedPhotoPath,
        language: widget.language,
        onSave: (updated) async {
          final updatedWithId = updated.copyWith(id: item.id, inventoryId: item.inventoryId);
          await DatabaseHelper.instance.updateInventoryItem(updatedWithId);
          widget.onRefresh();
          if (context.mounted) Navigator.pop(context);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteItem(item);
        },
      ),
    );
  }

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemOptionsSheet(
        onScanTap: widget.onAddScanTap,
        onAddFormTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddItemFormView(
                inventoryId: widget.activeList.id ?? 1,
                onItemAdded: widget.onRefresh,
              ),
            ),
          );
        },
        onBrowseTap: widget.onAddBrowseTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final displayItems = _filteredItems;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Search Bar
          InventorySearchBar(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            onFilterTap: _showFilterSheet,
            hasActiveFilters: _hasActiveFilters,
          ),

          // Tag Pills Bar
          InventoryTagBar(
            allLists: widget.allLists,
            activeList: widget.activeList,
            onListSelected: widget.onListChanged,
            onCreateNewTap: _showCreateListDialog,
          ),

          // Est. Budget Summary Bar
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

          // Main Items List OR Empty Inventory Placeholder
          Expanded(
            child: displayItems.isEmpty
                ? EmptyInventoryPlaceholder(
                    listName: widget.activeList.name,
                    language: widget.language,
                    onAddItemTap: () => _showAddModal(context),
                  )
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: displayItems.length,
                    onReorderItem: _onReorderItems,
                    itemBuilder: (context, index) {
                      final item = displayItems[index];
                      return Dismissible(
                        key: ValueKey('dismiss_${item.id ?? item.catalogId}_$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline, color: Colors.white, size: 24),
                              SizedBox(width: 6),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(widget.language == AppLanguage.hindi ? 'आइटम हटाएं?' : 'Delete Item?'),
                              content: Text(
                                widget.language == AppLanguage.hindi
                                    ? 'क्या आप "${item.customName}" को लिस्ट से हटाना चाहते हैं?'
                                    : 'Are you sure you want to remove "${item.customName}" from your inventory?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(widget.language == AppLanguage.hindi ? 'रद्द करें' : 'Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(widget.language == AppLanguage.hindi ? 'हटाएं' : 'Delete'),
                                ),
                              ],
                            ),
                          ) ?? false;
                        },
                        onDismissed: (direction) async {
                          if (item.id != null) {
                            final deletedItem = item;
                            await DatabaseHelper.instance.deleteInventoryItem(item.id!);
                            widget.onRefresh();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    widget.language == AppLanguage.hindi
                                        ? '"${deletedItem.customName}" हटा दिया गया'
                                        : '"${deletedItem.customName}" deleted',
                                  ),
                                  action: SnackBarAction(
                                    label: widget.language == AppLanguage.hindi ? 'वापस लाएं' : 'Undo',
                                    onPressed: () async {
                                      await DatabaseHelper.instance.addInventoryItem(deletedItem);
                                      widget.onRefresh();
                                    },
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: InventoryItemTile(
                          key: ValueKey(item.id ?? item.catalogId),
                          index: index,
                          item: item,
                          onTap: () => _editItem(item),
                          onQuantityChanged: (newQty) async {
                            if (item.id != null) {
                              final updated = item.copyWith(quantity: newQty);
                              await DatabaseHelper.instance.updateInventoryItem(updated);
                              widget.onRefresh();
                            }
                          },
                          onQuantityTap: () => _showEditQuantityDialog(item),
                          onUnitChanged: (newUnit) async {
                            if (item.id != null) {
                              final updated = item.copyWith(unit: newUnit);
                              await DatabaseHelper.instance.updateInventoryItem(updated);
                              widget.onRefresh();
                            }
                          },
                          onDeleteTap: () => _deleteItem(item),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar (Share on WhatsApp & Add Item FAB)
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
}
