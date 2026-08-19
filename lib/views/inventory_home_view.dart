import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/app_inventory_provider.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';
import '../models/inventory_list.dart';
import '../services/database_helper.dart';
import '../services/catalog_cache.dart';
import '../widgets/svg_icon.dart';
import '../services/localization_service.dart';
import '../services/share_service.dart';
import '../widgets/add_item_options_sheet.dart';
import '../widgets/create_list_dialog.dart';
import '../widgets/empty_inventory_placeholder.dart';
import '../widgets/inventory_filter_sheet.dart';
import '../widgets/inventory_item_tile.dart';
import '../widgets/inventory_search_bar.dart';
import '../widgets/inventory_tag_bar.dart';
import '../widgets/item_icon_widget.dart';
import 'add_item_form_view.dart';
import 'item_detail_sheet.dart';

class InventoryHomeView extends StatefulWidget {
  final InventoryList activeList;
  final List<InventoryList> allLists;
  final List<InventoryItem> items;
  final AppLanguage language;
  final VoidCallback onRefresh;
  final Function(InventoryList newList) onListChanged;
  final Function(String name) onListCreated;
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
  List<CatalogItem> _searchCatalogResults = [];
  Timer? _debounceTimer;
  final Set<String> _swipingItemIds = {};

  @override
  void initState() {
    super.initState();
    _localItems = List.from(widget.items);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      if (query.trim().isEmpty) {
        setState(() {
          _searchQuery = '';
          _searchCatalogResults = [];
        });
      } else {
        final results = await CatalogCache.instance.searchCatalog(
          query.trim(),
        );
        setState(() {
          _searchQuery = query;
          _searchCatalogResults = results;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant InventoryHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.activeList.id != widget.activeList.id ||
        oldWidget.language != widget.language) {
      _localItems = List.from(widget.items);
      _applySortOption(_selectedSortOption);
    }
  }

  void _applySortOption(String sortOpt) {
    _selectedSortOption = sortOpt;
    if (sortOpt == 'A - Z') {
      _localItems.sort((a, b) {
        final nameA = LocalizationService.getItemName(
          a.customName,
          a.nameHi,
          widget.language,
        ).toLowerCase();
        final nameB = LocalizationService.getItemName(
          b.customName,
          b.nameHi,
          widget.language,
        ).toLowerCase();
        return nameA.compareTo(nameB);
      });
    } else if (sortOpt == 'Z - A') {
      _localItems.sort((a, b) {
        final nameA = LocalizationService.getItemName(
          a.customName,
          a.nameHi,
          widget.language,
        ).toLowerCase();
        final nameB = LocalizationService.getItemName(
          b.customName,
          b.nameHi,
          widget.language,
        ).toLowerCase();
        return nameB.compareTo(nameA);
      });
    } else if (sortOpt == 'Qty: Low → High') {
      _localItems.sort((a, b) => a.quantity.compareTo(b.quantity));
    } else if (sortOpt == 'Qty: High → Low') {
      _localItems.sort((a, b) => b.quantity.compareTo(a.quantity));
    } else if (sortOpt == 'Price: High → Low') {
      _localItems.sort(
        (a, b) => (b.estimatedPrice ?? 0).compareTo(a.estimatedPrice ?? 0),
      );
    }
    if (sortOpt != 'Default') {
      DatabaseHelper.instance.updateItemsDisplayOrder(_localItems);
    }
  }

  List<InventoryItem> get _filteredItems {
    Iterable<InventoryItem> list = _localItems;

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where(
        (i) =>
            i.customName.toLowerCase().contains(q) ||
            i.nameHi.toLowerCase().contains(q) ||
            i.category.toLowerCase().contains(q),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => InventoryFilterSheet(
        categoryFilter: _selectedCategoryFilter,
        stockFilter: _selectedStockFilter,
        sortOption: _selectedSortOption,
        language: widget.language,
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
        onCreate: (name) {
          widget.onListCreated(name);
        },
      ),
    );
  }

  Future<void> _onReorderItems(int oldIndex, int newIndex) async {
    setState(() {
      _selectedSortOption = 'Default';

      final displayItems = _filteredItems;
      if (oldIndex < 0 || oldIndex >= displayItems.length) {
        return;
      }

      final itemToMove = displayItems[oldIndex];
      
      // Find the index of itemToMove in _localItems
      final actualOldIndex = _localItems.indexWhere((i) {
        if (i.id != null && itemToMove.id != null) {
          return i.id == itemToMove.id;
        }
        return i.catalogId == itemToMove.catalogId && i.customName == itemToMove.customName;
      });
      if (actualOldIndex == -1) {
        return;
      }

      // Remove from _localItems
      _localItems.removeAt(actualOldIndex);

      // Find the remaining filtered items after removing itemToMove
      final remainingFiltered = displayItems.where((item) {
        if (item.id != null && itemToMove.id != null) {
          return item.id != itemToMove.id;
        }
        return item.catalogId != itemToMove.catalogId || item.customName != itemToMove.customName;
      }).toList();

      if (remainingFiltered.isEmpty) {
        // Put it back if there are no other filtered items
        _localItems.insert(actualOldIndex, itemToMove);
        return;
      }

      int targetFilteredIndex = newIndex;
      if (newIndex > oldIndex) {
        targetFilteredIndex = newIndex - 1;
      }

      if (targetFilteredIndex >= remainingFiltered.length) {
        // Dragged to the very end of the filtered list.
        // Insert after the last item of remainingFiltered.
        final lastFilteredItem = remainingFiltered.last;
        final lastFilteredActualIndex = _localItems.indexWhere((i) {
          if (i.id != null && lastFilteredItem.id != null) {
            return i.id == lastFilteredItem.id;
          }
          return i.catalogId == lastFilteredItem.catalogId && i.customName == lastFilteredItem.customName;
        });
        if (lastFilteredActualIndex != -1) {
          _localItems.insert(lastFilteredActualIndex + 1, itemToMove);
        } else {
          _localItems.insert(actualOldIndex, itemToMove);
        }
      } else {
        // Dragged before the item at targetFilteredIndex in remainingFiltered.
        final targetFilteredItem = remainingFiltered[targetFilteredIndex];
        final targetActualIndex = _localItems.indexWhere((i) {
          if (i.id != null && targetFilteredItem.id != null) {
            return i.id == targetFilteredItem.id;
          }
          return i.catalogId == targetFilteredItem.catalogId && i.customName == targetFilteredItem.customName;
        });
        if (targetActualIndex != -1) {
          _localItems.insert(targetActualIndex, itemToMove);
        } else {
          _localItems.insert(actualOldIndex, itemToMove);
        }
      }
    });

    await DatabaseHelper.instance.updateItemsDisplayOrder(_localItems);
    widget.onRefresh();
  }

  @visibleForTesting
  List<InventoryItem> get localItemsForTest => _localItems;

  @visibleForTesting
  List<InventoryItem> get filteredItemsForTest => _filteredItems;

  @visibleForTesting
  void setCategoryFilterForTest(String category) {
    setState(() {
      _selectedCategoryFilter = category;
    });
  }

  @visibleForTesting
  Future<void> onReorderItemsForTest(int oldIndex, int newIndex) async {
    await _onReorderItems(oldIndex, newIndex);
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
    final isHindi = widget.language == AppLanguage.hindi;
    final displayName = item.catalogItem != null
        ? LocalizationService.getItemName(
            item.catalogItem!.nameEn,
            item.catalogItem!.nameHi,
            widget.language,
          )
        : LocalizationService.getItemName(
            item.customName,
            item.nameHi,
            widget.language,
          );

    final controller = TextEditingController(
      text: item.quantity % 1 == 0
          ? item.quantity.toInt().toString()
          : item.quantity.toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            isHindi ? '$displayName की मात्रा' : 'Quantity for $displayName',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: isHindi ? 'मात्रा दर्ज करें' : 'Enter Quantity',
                  suffixText: LocalizationService.getUnitLabel(
                    item.unit,
                    widget.language,
                  ).toUpperCase(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
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
              child: Text(isHindi ? 'सहेजें' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _handleDeleteWithUndo(InventoryItem item, int index) {
    if (item.id == null) return;
    final isHindi = widget.language == AppLanguage.hindi;
    final displayName = item.catalogItem != null
        ? LocalizationService.getItemName(
            item.catalogItem!.nameEn,
            item.catalogItem!.nameHi,
            widget.language,
          )
        : LocalizationService.getItemName(
            item.customName,
            item.nameHi,
            widget.language,
          );

    // 1. Remove from local list instantly for snappy feel
    setState(() {
      _localItems.removeWhere((i) => i.id == item.id);
    });

    final snackBar = SnackBar(
      duration: const Duration(seconds: 4),
      content: Text(
        isHindi ? '"$displayName" हटा दिया गया' : '"$displayName" deleted',
      ),
      action: SnackBarAction(
        label: isHindi ? 'वापस लाएं' : 'Undo',
        onPressed: () {
          // Re-insert at the original position
          setState(() {
            if (index >= 0 && index <= _localItems.length) {
              _localItems.insert(index, item);
            } else {
              _localItems.add(item);
            }
          });
        },
      ),
    );

    final controller = ScaffoldMessenger.of(context).showSnackBar(snackBar);

    controller.closed.then((reason) async {
      if (reason != SnackBarClosedReason.action) {
        // Not undone -> Commit deletion to DB
        await DatabaseHelper.instance.deleteInventoryItem(item.id!);
        // Re-sync display order
        await DatabaseHelper.instance.updateItemsDisplayOrder(_localItems);
        widget.onRefresh();
      } else {
        // Undone -> Re-sync order/refresh provider in background
        widget.onRefresh();
      }
    });
  }

  void _deleteItem(InventoryItem item) async {
    if (item.id == null) return;
    final idx = _localItems.indexWhere((i) => i.id == item.id);
    if (idx == -1) return;

    final isHindi = widget.language == AppLanguage.hindi;
    final displayName = item.catalogItem != null
        ? LocalizationService.getItemName(
            item.catalogItem!.nameEn,
            item.catalogItem!.nameHi,
            widget.language,
          )
        : LocalizationService.getItemName(
            item.customName,
            item.nameHi,
            widget.language,
          );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isHindi ? 'आइटम हटाएं?' : 'Delete Item?'),
        content: Text(
          isHindi
              ? 'क्या आप "$displayName" को लिस्ट से हटाना चाहते हैं?'
              : 'Are you sure you want to remove "$displayName" from your inventory?',
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
              _handleDeleteWithUndo(item, idx);
            },
            child: Text(isHindi ? 'हटाएं' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _editItem(InventoryItem item) {
    final catalog =
        item.catalogItem ??
        CatalogItem(
          id: item.catalogId,
          nameEn: item.customName,
          nameHi: item.nameHi.isNotEmpty ? item.nameHi : item.customName,
          category: item.category,
          categoryHi: item.category,
          aliases: [item.customName],
          defaultUnit: item.unit,
          allowedUnits: [
            item.unit,
            'KG',
            'G',
            'L',
            'ML',
            'PCS',
            'PKT',
            'BOTTLE',
            'CAN',
            'BOX',
            'STRIP',
            'SACHET',
          ],
          iconEmoji: '📦',
        );

    final inventory = context.read<AppInventoryProvider>();
    final allAddedItems = inventory.allItemsAcrossLists
        .where((ii) => ii.catalogId == item.catalogId)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemDetailSheet(
        catalogItem: catalog,
        existingItemsAcrossLists: allAddedItems,
        allLists: widget.allLists,
        activeInventoryId: widget.activeList.id ?? 1,
        capturedPhotoPath: item.capturedPhotoPath,
        language: widget.language,
        isEditMode: true,
        onSave: (customName, unit, price, listQuantities, addAnywayListIds) async {
          await inventory.saveItemToLists(
            catalogItem: catalog,
            listQuantities: listQuantities,
            customName: customName,
            unit: unit,
            estimatedPrice: price,
            capturedPhotoPath: item.capturedPhotoPath,
            addAnywayListIds: addAnywayListIds,
          );
          widget.onRefresh();
          if (context.mounted) Navigator.pop(context);
        },
        onDelete: () async {
          Navigator.pop(context);
          for (final existing in allAddedItems) {
            if (existing.id != null) {
              await DatabaseHelper.instance.deleteInventoryItem(existing.id!);
            }
          }
          widget.onRefresh();
        },
      ),
    );
  }

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemOptionsSheet(
        listName: widget.activeList.name,
        language: widget.language,
        onScanTap: widget.onAddScanTap,
        onAddFormTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddItemFormView(
                inventoryId: widget.activeList.id ?? 1,
                language: widget.language,
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
    final inventory = context.watch<AppInventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHindi = widget.language == AppLanguage.hindi;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final displayItems = _filteredItems;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            InventorySearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onFilterTap: _showFilterSheet,
              hasActiveFilters: _hasActiveFilters,
              language: widget.language,
            ),

            // Tag Pills Bar
            InventoryTagBar(
              allLists: widget.allLists,
              activeList: widget.activeList,
              language: widget.language,
              onListSelected: widget.onListChanged,
              onCreateNewTap: _showCreateListDialog,
            ),

            // Est. Budget Summary Bar
            if (_totalEstBudget > 0) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00C853).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          isHindi
                              ? '${displayItems.length} सामान'
                              : '${displayItems.length} items',
                          style: TextStyle(
                            color: subtextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isHindi
                              ? 'अनुमानित बजट: ₹${_totalEstBudget.toInt()}'
                              : 'Est. Budget: ₹${_totalEstBudget.toInt()}',
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

            // Main Items List OR Search Results OR Empty Inventory Placeholder
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _buildSearchResultsList(
                      context,
                      inventory,
                      isDark,
                      isHindi,
                      subtextColor,
                    )
                  : displayItems.isEmpty
                  ? EmptyInventoryPlaceholder(
                      listName: widget.activeList.name,
                      language: widget.language,
                      onAddItemTap: () => _showAddModal(context),
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: displayItems.length,
                      onReorderItem: _onReorderItems,
                      proxyDecorator: (Widget child, int index, Animation<double> animation) {
                        return Material(
                          color: Colors.transparent,
                          elevation: 0,
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final item = displayItems[index];
                        final displayName = item.catalogItem != null
                            ? LocalizationService.getItemName(
                                item.catalogItem!.nameEn,
                                item.catalogItem!.nameHi,
                                widget.language,
                              )
                            : LocalizationService.getItemName(
                                item.customName,
                                item.nameHi,
                                widget.language,
                              );

                        final itemIdStr = item.id?.toString() ?? item.catalogId;

                        return Dismissible(
                          key: ValueKey(
                            'dismiss_${item.id ?? item.catalogId}',
                          ),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                 const SvgIcon(
                                   'delete',
                                   color: Colors.white,
                                   size: 20,
                                 ),
                                 const SizedBox(width: 6),
                                Text(
                                  isHindi ? 'हटाएं' : 'Delete',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onUpdate: (details) {
                            final isSwipingNow = details.progress > 0.02;
                            final wasSwiping = _swipingItemIds.contains(itemIdStr);
                            if (isSwipingNow != wasSwiping) {
                              setState(() {
                                if (isSwipingNow) {
                                  _swipingItemIds.add(itemIdStr);
                                } else {
                                  _swipingItemIds.remove(itemIdStr);
                                }
                              });
                            }
                          },
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(
                                      isHindi ? 'आइटम हटाएं?' : 'Delete Item?',
                                    ),
                                    content: Text(
                                      isHindi
                                          ? 'क्या आप "$displayName" को लिस्ट से हटाना चाहते हैं?'
                                          : 'Are you sure you want to remove "$displayName" from your inventory?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _swipingItemIds.remove(itemIdStr);
                                          });
                                          Navigator.pop(ctx, false);
                                        },
                                        child: Text(
                                          isHindi ? 'रद्द करें' : 'Cancel',
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFEF4444,
                                          ),
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text(
                                          isHindi ? 'हटाएं' : 'Delete',
                                        ),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (direction) {
                            setState(() {
                              _swipingItemIds.remove(itemIdStr);
                            });
                            final idx = _localItems.indexWhere((i) => i.id == item.id);
                            if (idx != -1) {
                              _handleDeleteWithUndo(item, idx);
                            }
                          },
                          child: RepaintBoundary(
                            child: InventoryItemTile(
                              key: ValueKey(item.id ?? item.catalogId),
                              index: index,
                              item: item,
                              language: widget.language,
                              isSwiping: _swipingItemIds.contains(itemIdStr),
                              onTap: () => _editItem(item),
                              onQuantityChanged: (newQty) async {
                                if (item.id != null) {
                                  setState(() {
                                    final idx = _localItems.indexWhere((i) => i.id == item.id);
                                    if (idx != -1) {
                                      _localItems[idx] = _localItems[idx].copyWith(quantity: newQty);
                                    }
                                  });
                                  final updated = item.copyWith(
                                    quantity: newQty,
                                  );
                                  await DatabaseHelper.instance
                                      .updateInventoryItem(updated);
                                  widget.onRefresh();
                                }
                              },
                              onQuantityTap: () =>
                                  _showEditQuantityDialog(item),
                              onUnitChanged: (newUnit) async {
                                if (item.id != null) {
                                  final updated = item.copyWith(unit: newUnit);
                                  await DatabaseHelper.instance
                                      .updateInventoryItem(updated);
                                  widget.onRefresh();
                                }
                              },
                              onDeleteTap: () => _deleteItem(item),
                            ),
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
                      onPressed: () async {
                        final activeListItems = widget.activeList.id != null
                            ? await DatabaseHelper.instance
                                  .getInventoryItemsForList(
                                    widget.activeList.id!,
                                  )
                            : _localItems;
                        ShareService.shareToWhatsApp(
                          activeListItems.isNotEmpty
                              ? activeListItems
                              : _localItems,
                          listName: widget.activeList.name,
                          language: widget.language,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           const SvgIcon(
                            'share',
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isHindi
                                ? "WhatsApp पर शेयर करें"
                                : "Share On WhatsApp",
                            style: const TextStyle(
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
                    child: const SvgIcon('add', color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(
    BuildContext context,
    AppInventoryProvider inventory,
    bool isDark,
    bool isHindi,
    Color subtextColor,
  ) {
    if (_searchCatalogResults.isEmpty) {
      return Center(
        child: Text(
          isHindi
              ? 'खोज के अनुसार कोई सामान नहीं मिला।'
              : 'No items found matching search.',
          style: TextStyle(fontSize: 15, color: subtextColor),
        ),
      );
    }

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFCBD5E1);
    final textColor = isDark ? Colors.white : const Color(0xFF000000);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _searchCatalogResults.length,
      itemBuilder: (context, index) {
        final item = _searchCatalogResults[index];
        final displayName = LocalizationService.getItemName(
          item.nameEn,
          item.nameHi,
          widget.language,
        );
        final allAddedItems =
            inventory.catalogIdToItemsAcrossLists[item.id] ?? const [];

        return RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: cardBg,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: borderColor),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                leading: ItemIconWidget(
                  itemId: item.id,
                  category: item.category,
                  emojiHint: item.iconEmoji,
                  size: 50,
                  iconSize: 24,
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (allAddedItems.isNotEmpty) ...[
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(left: 8),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C853),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          allAddedItems.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  isHindi ? item.categoryHi : item.category,
                  style: TextStyle(color: subtextColor, fontSize: 13),
                ),
                trailing: SvgIcon(
                  'add',
                  color: isDark
                      ? const Color(0xFF00C853)
                      : const Color(0xFF0F172A),
                  size: 18,
                ),
                onTap: () {
                  final catalog = CatalogItem(
                    id: item.id,
                    nameEn: item.nameEn,
                    nameHi: item.nameHi,
                    category: item.category,
                    categoryHi: item.categoryHi,
                    aliases: item.aliases,
                    defaultUnit: item.defaultUnit,
                    allowedUnits: item.allowedUnits,
                    iconEmoji: item.iconEmoji,
                  );
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ItemDetailSheet(
                      catalogItem: catalog,
                      existingItemsAcrossLists: allAddedItems,
                      allLists: inventory.allLists,
                      activeInventoryId: inventory.activeList?.id ?? 1,
                      capturedPhotoPath: null,
                      language: widget.language,
                      onSave: (customName, unit, price, listQuantities, addAnywayListIds) async {
                        await inventory.saveItemToLists(
                          catalogItem: catalog,
                          listQuantities: listQuantities,
                          customName: customName,
                          unit: unit,
                          estimatedPrice: price,
                          capturedPhotoPath: null,
                          addAnywayListIds: addAnywayListIds,
                        );
                        widget.onRefresh();
                        if (context.mounted) Navigator.pop(context);
                      },
                      onDelete: () async {
                        Navigator.pop(context);
                        for (final existing in allAddedItems) {
                          if (existing.id != null) {
                            await DatabaseHelper.instance.deleteInventoryItem(
                              existing.id!,
                            );
                          }
                        }
                        widget.onRefresh();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
