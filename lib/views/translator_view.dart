import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../data/indian_pantry_catalog.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';
import '../services/localization_service.dart';
import '../widgets/item_icon_widget.dart';

class TranslatorView extends StatefulWidget {
  final AppLanguage language;
  final Function(InventoryItem item) onItemAdded;

  const TranslatorView({
    super.key,
    this.language = AppLanguage.english,
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
    final isHindi = widget.language == AppLanguage.hindi;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          isHindi ? 'अनुवादक' : 'Translator',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
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
              child: Row(
                children: [
                  const Icon(Icons.g_translate, color: Color(0xFF0284C7), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isHindi
                          ? 'अंग्रेजी या हिंदी नाम (जैसे "Atta", "गेहूं", "Toor Dal", "हल्दी") लिखकर तुरंत अनुवाद करें!'
                          : 'Type any English or Hindi name (e.g. "Atta", "gehu", "Toor Dal", "haldi") to translate instantly!',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ShadInput(
              controller: _inputController,
              placeholder: Text(
                isHindi ? 'अंग्रेजी या हिंदी में नाम लिखें...' : 'Type item name...',
              ),
              leading: const Icon(Icons.search, size: 20),
              onChanged: _translateInput,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _inputController.text.isEmpty
                            ? (isHindi
                                ? 'सामान का नाम खोजें...'
                                : 'Start typing above to translate item names.')
                            : (isHindi
                                ? '"${_inputController.text}" के लिए कोई अनुवाद नहीं मिला।'
                                : 'No translation found for "${_inputController.text}".'),
                        style: const TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        final nameEnClean = LocalizationService.getItemName(
                          item.nameEn,
                          item.nameHi,
                          AppLanguage.english,
                        );
                        final nameHiClean = LocalizationService.getItemName(
                          item.nameEn,
                          item.nameHi,
                          AppLanguage.hindi,
                        );
                        final categoryDisplay = LocalizationService.getCategoryName(
                          item.category,
                          widget.language,
                          categoryHi: item.categoryHi,
                        );

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
                                Flexible(
                                  child: Text(
                                    nameEnClean,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.compare_arrows, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    nameHiClean,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(categoryDisplay, style: const TextStyle(fontSize: 13, color: Colors.grey)),
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
                              child: Text(
                                isHindi ? 'सामान जोड़ें' : 'Add Item',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
     ),
    );
  }
}
