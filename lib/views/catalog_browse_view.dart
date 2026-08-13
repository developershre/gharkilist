import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';
import '../services/database_helper.dart';
import 'item_detail_sheet.dart';

class CatalogBrowseView extends StatefulWidget {
  final String? capturedPhotoPath;
  final Function(InventoryItem item) onItemAdded;

  const CatalogBrowseView({
    super.key,
    this.capturedPhotoPath,
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

  final List<String> _voiceSuggestions = [
    'Atta',
    'Basmati Rice',
    'Toor Dal',
    'Desi Ghee',
    'Sugar',
    'Agarbatti',
    'Dolo 650',
    'Milk'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final items = await DatabaseHelper.instance.getAllCatalogItems();
    final categories = await DatabaseHelper.instance.getCatalogCategories();
    setState(() {
      _catalogItems = items;
      _categories = ['All', ...categories];
      _isLoading = false;
    });
  }

  Future<void> _onSearchChanged(String query) async {
    final results = await DatabaseHelper.instance.searchCatalog(
      query,
      category: _selectedCategory,
    );
    setState(() {
      _catalogItems = results;
    });
  }

  void _showVoiceSearchModal() {
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Color(0xFF0284C7), size: 38),
              ),
              const SizedBox(height: 16),
              const Text(
                'बोल कर सामान ढूंढें (Voice Search)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap a voice sample or speak item name (e.g. Atta, Dal, Agarbatti):',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _voiceSuggestions.map((s) {
                  return ActionChip(
                    avatar: const Icon(Icons.mic, size: 16, color: Color(0xFF0284C7)),
                    label: Text(s, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      _searchController.text = s;
                      _onSearchChanged(s);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openItemDetail(CatalogItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemDetailSheet(
        catalogItem: item,
        capturedPhotoPath: widget.capturedPhotoPath,
        onSave: (inventoryItem) {
          widget.onItemAdded(inventoryItem);
          Navigator.pop(context); // Close browse view
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('Catalog (सामान सूची)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          if (widget.capturedPhotoPath != null)
            Container(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt, color: Color(0xFF0284C7), size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Photo captured! Select matching item below to save photo.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          // Search & Voice Bar
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Expanded(
                  child: ShadInput(
                    controller: _searchController,
                    placeholder: const Text('Search Atta, Dal, Salt, Pooja... (खोजें)'),
                    leading: const Icon(Icons.search, size: 20),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.mic, color: Color(0xFF0284C7), size: 26),
                  tooltip: 'बोल कर ढूंढें (Voice Search)',
                  onPressed: _showVoiceSearchModal,
                ),
              ],
            ),
          ),
          // Category Filter Horizontal Pills
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0F172A),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                        _onSearchChanged(_searchController.text);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Catalog Grid / List with Large Fonts
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _catalogItems.isEmpty
                    ? const Center(child: Text('No items found matching search.', style: TextStyle(fontSize: 15)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: _catalogItems.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _catalogItems[index];
                          return Card(
                            elevation: 0,
                            color: cardBgColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: borderColor),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: Text(
                                item.iconEmoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                              title: Text(
                                item.nameEn,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18, // Large Item Title
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              subtitle: Text(
                                item.nameHi.isNotEmpty
                                    ? '${item.nameHi} • ${item.category}'
                                    : item.category,
                                style: const TextStyle(
                                  color: Color(0xFF0284C7),
                                  fontSize: 14, // Large Subtitle
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF0F172A), size: 26),
                              onTap: () => _openItemDetail(item),
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
