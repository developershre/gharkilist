import 'dart:async';
import 'package:flutter/material.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import '../widgets/gharkilist_logo.dart';
import '../widgets/item_icon_widget.dart';
import 'item_detail_sheet.dart';

class CatalogBrowseView extends StatefulWidget {
  final String? capturedPhotoPath;
  final AppLanguage language;
  final Function(InventoryItem item) onItemAdded;

  const CatalogBrowseView({
    super.key,
    this.capturedPhotoPath,
    this.language = AppLanguage.english,
    required this.onItemAdded,
  });

  @override
  State<CatalogBrowseView> createState() => _CatalogBrowseViewState();
}

class _CatalogBrowseViewState extends State<CatalogBrowseView> {
  final TextEditingController _searchController = TextEditingController();
  List<CatalogItem> _catalogItems = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final items = await DatabaseHelper.instance.getAllCatalogItems();
    final categories = await DatabaseHelper.instance.getCatalogCategories();
    if (mounted) {
      setState(() {
        _catalogItems = items;
        _categories = ['All', ...categories];
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () async {
      final results = await DatabaseHelper.instance.searchCatalog(
        query,
        category: _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _catalogItems = results;
        });
      }
    });
  }

  void _openItemDetail(CatalogItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemDetailSheet(
        catalogItem: item,
        capturedPhotoPath: widget.capturedPhotoPath,
        language: widget.language,
        onSave: (inventoryItem) {
          widget.onItemAdded(inventoryItem);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final appBarBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final iconColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const GharkiListLogoWidget(),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: iconColor, size: 26),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: subtextColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor, fontSize: 16),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: subtextColor, fontSize: 16),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  Icon(Icons.tune, color: subtextColor, size: 20),
                ],
              ),
            ),
          ),

          // Horizontal Category Filter Pills
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;

                if (isSelected) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cat,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                      _onSearchChanged(_searchController.text);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Catalog Items List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _catalogItems.isEmpty
                    ? Center(
                        child: Text(
                          'No items found matching search.',
                          style: TextStyle(fontSize: 15, color: subtextColor),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: _catalogItems.length,
                        itemBuilder: (context, index) {
                          final item = _catalogItems[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: cardBg,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: borderColor),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                leading: ItemIconWidget(
                                  itemId: item.id,
                                  category: item.category,
                                  emojiHint: item.iconEmoji,
                                  size: 50,
                                  iconSize: 24,
                                ),
                                title: Text(
                                  item.nameEn.replaceAll(RegExp(r'\s*\([^)]*\)'), ''),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: textColor,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.add_circle_outline,
                                  color: isDark ? const Color(0xFF00C853) : const Color(0xFF000000),
                                  size: 26,
                                ),
                                onTap: () => _openItemDetail(item),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

