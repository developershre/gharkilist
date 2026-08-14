import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../data/indian_pantry_catalog.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';
import '../models/inventory_list.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import '../services/share_service.dart';
import '../widgets/item_icon_widget.dart';

final List<CatalogItem> _quickStaplesCache = seedIndianCatalog.where((i) => [
      'grains_atta',
      'grains_basmati_rice',
      'dal_toor',
      'spice_sugar',
      'dairy_milk_packet',
      'oil_ghee',
      'spice_salt',
      'spice_chai_patti'
    ].contains(i.id)).toList();

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
  String _selectedStatusFilter = 'ALL'; // 'ALL', 'OUT', 'LOW'
  late List<InventoryItem> _localItems;

  @override
  void initState() {
    super.initState();
    _localItems = List.from(widget.items);
  }

  @override
  void didUpdateWidget(covariant InventoryHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _localItems = List.from(widget.items);
    }
  }

  Future<void> _instantAddStaple(BuildContext context, CatalogItem catalogItem) async {
    final invItem = InventoryItem(
      inventoryId: widget.activeList.id ?? 1,
      catalogId: catalogItem.id,
      customName: catalogItem.nameEn,
      nameHi: catalogItem.nameHi,
      category: catalogItem.category,
      quantity: 1.0,
      unit: catalogItem.defaultUnit,
      catalogItem: catalogItem,
    );
    await DatabaseHelper.instance.addInventoryItem(invItem);
    widget.onRefresh();
    if (context.mounted) {
      final name = LocalizationService.getItemName(catalogItem.nameEn, catalogItem.nameHi, widget.language);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "$name" to ${widget.activeList.name}!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<InventoryItem> get _filteredItems {
    if (_selectedStatusFilter == 'OUT') {
      return _localItems.where((i) => i.isOut).toList();
    } else if (_selectedStatusFilter == 'LOW') {
      return _localItems.where((i) => i.isLow && !i.isOut).toList();
    }
    return _localItems;
  }

  double get _totalEstimatedBudget {
    double total = 0.0;
    for (final item in _localItems) {
      if (item.estimatedPrice != null && item.estimatedPrice! > 0) {
        total += item.quantity * item.estimatedPrice!;
      }
    }
    return total;
  }

  void _onReorderItems(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _localItems.removeAt(oldIndex);
      _localItems.insert(newIndex, item);
    });

    await DatabaseHelper.instance.updateItemsDisplayOrder(_localItems);
    widget.onRefresh();
  }

  void _showAddModal(BuildContext context) {
    final isHindi = widget.language == AppLanguage.hindi;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isHindi ? 'सामान जोड़ें: "${widget.activeList.name}"' : 'Add Item to "${widget.activeList.name}"',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0EA5E9)),
                ),
                title: Text(
                  isHindi ? 'फोटो खींचें (Camera Scan)' : 'Scan Photo',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isHindi ? 'पैकेट या बोरी की फोटो लें' : 'Take photo of bag or package',
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onAddScanTap();
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.search_outlined, color: Color(0xFF6366F1)),
                ),
                title: Text(
                  isHindi ? 'सूची देखें (Browse Catalog)' : 'Browse 200+ Catalog',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isHindi ? 'आटा, दाल, मसाले, पूजा सामान खोजें' : 'Search Atta, Dal, Spices, Dairy, Pooja, etc.',
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onAddBrowseTap();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHindi = widget.language == AppLanguage.hindi;
    final filtered = _filteredItems;
    final totalCount = widget.items.length;
    final outCount = widget.items.where((i) => i.isOut).length;
    final lowCount = widget.items.where((i) => i.isLow && !i.isOut).length;
    final capped = totalCount >= DatabaseHelper.freeTierCap;
    final totalBudget = _totalEstimatedBudget;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0); // Slate 700 / Slate 200

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Free Tier & Estimated Kirana Budget Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: capped
                          ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2))
                          : cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: capped ? const Color(0xFFEF4444) : borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('${widget.activeList.iconEmoji} ', style: const TextStyle(fontSize: 22)),
                                Text(
                                  '${widget.activeList.name}: $totalCount / ${DatabaseHelper.freeTierCap}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: capped ? const Color(0xFFEF4444) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                  ),
                                ),
                              ],
                            ),
                            if (totalBudget > 0)
                              ShadBadge(
                                child: Text('Est. ₹${totalBudget.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              )
                            else
                              ShadBadge(
                                child: Text(
                                  capped ? 'Cap Reached' : '${DatabaseHelper.freeTierCap - totalCount} slots left',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (totalCount / DatabaseHelper.freeTierCap).clamp(0.0, 1.0),
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              capped ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Smart Status Filter Pills & Drag Hint
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          side: BorderSide(color: borderColor),
                          label: Text(
                            isHindi ? '🟢 सब (${widget.items.length})' : '🟢 All (${widget.items.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedStatusFilter == 'ALL'
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                            ),
                          ),
                          selected: _selectedStatusFilter == 'ALL',
                          selectedColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          onSelected: (val) {
                            if (val) setState(() => _selectedStatusFilter = 'ALL');
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          side: BorderSide(color: _selectedStatusFilter == 'OUT' ? const Color(0xFFEF4444) : borderColor),
                          label: Text(
                            isHindi ? '🔴 खत्म ($outCount)' : '🔴 Out ($outCount)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedStatusFilter == 'OUT'
                                  ? Colors.white
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                            ),
                          ),
                          selected: _selectedStatusFilter == 'OUT',
                          selectedColor: const Color(0xFFEF4444),
                          onSelected: (val) {
                            setState(() => _selectedStatusFilter = val ? 'OUT' : 'ALL');
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          side: BorderSide(color: _selectedStatusFilter == 'LOW' ? const Color(0xFFF59E0B) : borderColor),
                          label: Text(
                            isHindi ? '🟡 कम ($lowCount)' : '🟡 Low ($lowCount)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedStatusFilter == 'LOW'
                                  ? Colors.white
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                            ),
                          ),
                          selected: _selectedStatusFilter == 'LOW',
                          selectedColor: const Color(0xFFF59E0B),
                          onSelected: (val) {
                            setState(() => _selectedStatusFilter = val ? 'LOW' : 'ALL');
                          },
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swap_vert, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                isHindi ? 'क्रम बदलें' : 'Reorder',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Instant 1-Click Quick Add Staples Row
                  Text(
                    isHindi ? '⚡ 1-क्लिक तुरंत जोड़ें:' : '⚡ 1-Click Quick Add:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 46,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickStaplesCache.length,
                      itemBuilder: (context, index) {
                        final item = _quickStaplesCache[index];
                        final itemName = LocalizationService.getItemName(item.nameEn, item.nameHi, widget.language);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            side: BorderSide(color: borderColor),
                            backgroundColor: cardBgColor,
                            avatar: ItemIconWidget(itemId: item.id, category: item.category, size: 22, iconSize: 11),
                            label: Text(
                              '+ $itemName',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            onPressed: () => _instantAddStaple(context, item),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reorderable Drag-and-Drop List with Single Clean Language Item Names
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.filter_alt_off, size: 52, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      isHindi ? 'कोई सामान नहीं मिला' : 'No items match filter',
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedStatusFilter = 'ALL'),
                      child: Text(isHindi ? 'सब देखें' : 'Show All Items', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverReorderableList(
              itemCount: filtered.length,
              onReorderItem: _onReorderItems,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final itemKey = ValueKey(item.id ?? item.catalogId);
                final displayName = LocalizationService.getItemName(item.customName, item.nameHi, widget.language);

                return ReorderableDelayedDragStartListener(
                  key: itemKey,
                  index: index,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.isOut
                            ? const Color(0xFFEF4444)
                            : item.isLow
                                ? const Color(0xFFF59E0B)
                                : borderColor, // Slate 700 in Dark Mode
                        width: (item.isOut || item.isLow) ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: const Color(0xFF64748B).withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Drag Handle Icon (⋮⋮)
                            const ReorderableDragStartListener(
                              index: 0,
                              child: Icon(Icons.drag_indicator, color: Color(0xFF94A3B8), size: 24),
                            ),
                            const SizedBox(width: 8),
                            ItemIconWidget(
                              itemId: item.catalogId,
                              category: item.category,
                              emojiHint: item.catalogItem?.iconEmoji,
                              size: 44,
                              iconSize: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  decoration: item.isOut ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            // Large In-Line Quantity Stepper (- 1 kg +)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      if (item.id != null && item.quantity > 0.5) {
                                        final step = (item.unit == 'g' || item.unit == 'ml') ? 100.0 : 1.0;
                                        final updatedQty = (item.quantity - step).clamp(0.5, 999.0);
                                        await DatabaseHelper.instance.updateInventoryItem(
                                          item.copyWith(quantity: updatedQty),
                                        );
                                        widget.onRefresh();
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Icon(Icons.remove, size: 18),
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      if (item.id != null) {
                                        final step = (item.unit == 'g' || item.unit == 'ml') ? 100.0 : 1.0;
                                        final updatedQty = item.quantity + step;
                                        await DatabaseHelper.instance.updateInventoryItem(
                                          item.copyWith(quantity: updatedQty),
                                        );
                                        widget.onRefresh();
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Icon(Icons.add, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 22),
                              onPressed: item.id != null
                                  ? () async {
                                      await DatabaseHelper.instance.deleteInventoryItem(item.id!);
                                      widget.onRefresh();
                                    }
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 10),

                        // Large 1-Tap Direct Status Controls: Available / Low / Out
                        Row(
                          children: [
                            Text(
                              isHindi ? 'स्थिति:' : 'Status:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatusButton(
                                    label: isHindi ? 'स्टॉक में है' : 'In Stock',
                                    isSelected: !item.isLow && !item.isOut,
                                    activeColor: const Color(0xFF22C55E),
                                    borderColor: borderColor,
                                    onTap: () async {
                                      if (item.id != null) {
                                        await DatabaseHelper.instance.toggleStockStatus(
                                          item.id!,
                                          isLow: false,
                                          isOut: false,
                                        );
                                        widget.onRefresh();
                                      }
                                    },
                                  ),
                                  _buildStatusButton(
                                    label: isHindi ? 'कम है' : 'Low',
                                    isSelected: item.isLow,
                                    activeColor: const Color(0xFFF59E0B),
                                    borderColor: borderColor,
                                    onTap: () async {
                                      if (item.id != null) {
                                        await DatabaseHelper.instance.toggleStockStatus(
                                          item.id!,
                                          isLow: true,
                                          isOut: false,
                                        );
                                        widget.onRefresh();
                                      }
                                    },
                                  ),
                                  _buildStatusButton(
                                    label: isHindi ? 'खत्म है' : 'Out',
                                    isSelected: item.isOut,
                                    activeColor: const Color(0xFFEF4444),
                                    borderColor: borderColor,
                                    onTap: () async {
                                      if (item.id != null) {
                                        await DatabaseHelper.instance.toggleStockStatus(
                                          item.id!,
                                          isLow: false,
                                          isOut: true,
                                        );
                                        widget.onRefresh();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
        ],
      ),

      // Sticky Bottom Bar with Prominent Green WhatsApp Share Button
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardBgColor,
          border: Border(top: BorderSide(color: borderColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.share, size: 22),
                  label: Text(
                    isHindi ? 'व्हाट्सएप पर सूची भेजें' : 'Send List on WhatsApp',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () => ShareService.shareToWhatsApp(
                    widget.items,
                    listName: widget.activeList.name,
                    language: widget.language,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              onPressed: () {
                if (capped) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Free tier cap reached (15 items max).'),
                    ),
                  );
                  return;
                }
                _showAddModal(context);
              },
              backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
              foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              child: const Icon(Icons.add, size: 26),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : borderColor,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}
