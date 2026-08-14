import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../data/indian_pantry_catalog.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';
import '../widgets/item_icon_widget.dart';

class TranslatorView extends StatefulWidget {
  final Function(InventoryItem item) onItemAdded;

  const TranslatorView({
    super.key,
    required this.onItemAdded,
  });

  @override
  State<TranslatorView> createState() => _TranslatorViewState();
}

class _TranslatorViewState extends State<TranslatorView> {
  final TextEditingController _inputController = TextEditingController();
  List<CatalogItem> _searchResults = [];

  void _translateInput(String input) {
    if (input.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final query = input.trim().toLowerCase();
    final results = seedIndianCatalog.where((item) => item.matchesSearch(query)).toList();

    setState(() {
      _searchResults = results;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('Translator (हिंदी / English)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.g_translate, color: Color(0xFF0284C7), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Type any English or Hindi name (e.g. "Atta", "गेहूं", "Toor Dal", "हल्दी") to translate instantly!',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ShadInput(
              controller: _inputController,
              placeholder: const Text('Type item name in English or हिंदी...'),
              leading: const Icon(Icons.search, size: 20),
              onChanged: _translateInput,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _inputController.text.isEmpty
                            ? 'Start typing above to translate item names.'
                            : 'No translation found for "${_inputController.text}".',
                        style: const TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return Card(
                          elevation: 0,
                          color: cardBgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: borderColor),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: ItemIconWidget(
                              itemId: item.id,
                              category: item.category,
                              emojiHint: item.iconEmoji,
                              size: 42,
                              iconSize: 20,
                            ),
                            title: Row(
                              children: [
                                Text(
                                  item.nameEn,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.compare_arrows, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.nameHi,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text('Category: ${item.category}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                                foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              ),
                              onPressed: () {
                                final inv = InventoryItem(
                                  inventoryId: 1,
                                  catalogId: item.id,
                                  customName: item.nameEn,
                                  nameHi: item.nameHi,
                                  category: item.category,
                                  quantity: 1.0,
                                  unit: item.defaultUnit,
                                  catalogItem: item,
                                );
                                widget.onItemAdded(inv);
                                Navigator.pop(context);
                              },
                              child: const Text('Add Item', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
