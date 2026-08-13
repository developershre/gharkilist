import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../data/indian_pantry_catalog.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';
import '../models/inventory_list.dart';
import '../services/database_helper.dart';
import '../services/share_service.dart';
import 'inventory_switcher_sheet.dart';

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
  final VoidCallback onRefresh;
  final Function(InventoryList newList) onListChanged;
  final VoidCallback onAddScanTap;
  final VoidCallback onAddBrowseTap;

  const InventoryHomeView({
    super.key,
    required this.activeList,
    required this.items,
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

  void _openSwitcherSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InventorySwitcherSheet(
        activeList: widget.activeList,
        onListSelected: widget.onListChanged,
      ),
    );
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
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${catalogItem.nameEn}" to ${widget.activeList.name}!'),
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
                'Add Item to "${widget.activeList.name}"',
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
                title: const Text('Camera Scan (फोटो खींचें)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                subtitle: const Text('Take photo of bag/package', style: TextStyle(fontSize: 13)),
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
                title: const Text('Browse 200+ Catalog (सूची देखें)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                subtitle: const Text('Search Atta, Dal, Spices, Dairy, Pooja, etc.', style: TextStyle(fontSize: 13)),
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
    final filtered = _filteredItems;
    final totalCount = widget.items.length;
    final outCount = widget.items.where((i) => i.isOut).length;
    final lowCount = widget.items.where((i) => i.isLow && !i.isOut).length;
    final capped = totalCount >= DatabaseHelper.freeTierCap;
    final totalBudget = _totalEstimatedBudget;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: bgColor,
            floating: true,
            pinned: true,
            elevation: 0,
            title: InkWell(
              onTap: () => _openSwitcherSheet(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.activeList.iconEmoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        widget.activeList.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                  ],
                ),
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.copy, color: Color(0xFF38BDF8), size: 22),
                tooltip: 'Copy Grocery List Text',
                onPressed: () async {
                  await ShareService.copyToClipboard(widget.items, listName: widget.activeList.name);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Grocery list copied to clipboard! 📋')),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Color(0xFF22C55E), size: 22),
                tooltip: 'Share Grocery List on WhatsApp',
                onPressed: () => ShareService.shareToWhatsApp(widget.items, listName: widget.activeList.name),
              ),
            ],
          ),
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
                          ? const Color(0xFFFEF2F2)
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: capped ? const Color(0xFFFCA5A5) : borderColor,
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
                          label: Text(
                            '🟢 All (${widget.items.length})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          selected: _selectedStatusFilter == 'ALL',
                          selectedColor: const Color(0xFFE2E8F0),
                          onSelected: (val) {
                            if (val) setState(() => _selectedStatusFilter = 'ALL');
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(
                            '🔴 Out ($outCount)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          selected: _selectedStatusFilter == 'OUT',
                          selectedColor: const Color(0xFFFCA5A5),
                          onSelected: (val) {
                            setState(() => _selectedStatusFilter = val ? 'OUT' : 'ALL');
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(
                            '🟡 Low ($lowCount)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          selected: _selectedStatusFilter == 'LOW',
                          selectedColor: const Color(0xFFFDE68A),
                          onSelected: (val) {
                            setState(() => _selectedStatusFilter = val ? 'LOW' : 'ALL');
                          },
                        ),
                        const SizedBox(width: 14),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_vert, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              'Drag to reorder',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Instant 1-Click Quick Add Staples Row
                  Text(
                    '⚡ 1-Click Quick Add Essentials:',
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
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            avatar: Text(item.iconEmoji, style: const TextStyle(fontSize: 18)),
                            label: Text(
                              '+ ${item.nameEn.split('(')[0].trim()}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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

          // Reorderable Drag-and-Drop List with Large Fonts
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
                      'No items match filter "$_selectedStatusFilter"',
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedStatusFilter = 'ALL'),
                      child: const Text('Show All Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                                : borderColor,
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
                            Text(
                              item.catalogItem?.iconEmoji ?? '📦',
                              style: const TextStyle(fontSize: 34),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.customName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18, // Large Font Title
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      decoration: item.isOut ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  if (item.nameHi.isNotEmpty)
                                    Text(
                                      item.nameHi,
                                      style: TextStyle(
                                        fontSize: 14, // Large Font Hindi Subtitle
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                      ),
                                    ),
                                ],
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
                                      fontSize: 14, // Large Stepper Font
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
                              'Status:',
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
                                    label: 'In Stock',
                                    labelHi: 'है',
                                    isSelected: !item.isLow && !item.isOut,
                                    activeColor: const Color(0xFF22C55E),
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
                                    label: 'Low',
                                    labelHi: 'कम',
                                    isSelected: item.isLow,
                                    activeColor: const Color(0xFFF59E0B),
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
                                    label: 'Out',
                                    labelHi: 'खत्म',
                                    isSelected: item.isOut,
                                    activeColor: const Color(0xFFEF4444),
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
                  label: const Text(
                    'Send List on WhatsApp / व्हाट्सएप भेजें',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () => ShareService.shareToWhatsApp(widget.items, listName: widget.activeList.name),
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
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add, size: 26),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required String labelHi,
    required bool isSelected,
    required Color activeColor,
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
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        child: Text(
          '$label ($labelHi)',
          style: TextStyle(
            fontSize: 13, // Large Status Button Font
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
