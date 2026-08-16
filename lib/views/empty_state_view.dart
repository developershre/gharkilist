import 'package:flutter/material.dart';
import '../models/catalog_item.dart';
import '../models/inventory_list.dart';
import '../services/localization_service.dart';
import '../widgets/add_item_options_sheet.dart';
import '../widgets/empty_inventory_placeholder.dart';
import '../widgets/inventory_tag_bar.dart';

class EmptyStateView extends StatelessWidget {
  final InventoryList activeList;
  final List<InventoryList> allLists;
  final AppLanguage language;
  final VoidCallback onScanTap;
  final VoidCallback onBrowseTap;
  final Function(CatalogItem item) onQuickAddCatalogItem;
  final Function(InventoryList newList)? onListChanged;
  final Function(InventoryList newList)? onListCreated;

  const EmptyStateView({
    super.key,
    required this.activeList,
    this.allLists = const [],
    required this.language,
    required this.onScanTap,
    required this.onBrowseTap,
    required this.onQuickAddCatalogItem,
    this.onListChanged,
    this.onListCreated,
  });

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemOptionsSheet(
        language: language,
        onScanTap: onScanTap,
        onAddFormTap: () {},
        onBrowseTap: onBrowseTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          InventoryTagBar(
            allLists: allLists,
            activeList: activeList,
            language: language,
            onListSelected: (list) {
              if (onListChanged != null) onListChanged!(list);
            },
            onCreateNewTap: () {},
          ),
          Expanded(
            child: EmptyInventoryPlaceholder(
              listName: activeList.name,
              language: language,
              onAddItemTap: () => _showAddModal(context),
            ),
          ),
        ],
      ),
    );
  }
}
