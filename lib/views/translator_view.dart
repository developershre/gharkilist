import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_item.dart';
import '../services/translation_service.dart';
import 'item_detail_sheet.dart';

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
  bool _isEngToHindi = true;
  TranslationResult? _result;

  final List<String> _quickEngSuggestions = [
    'Wheat Flour',
    'Toor Dal',
    'Turmeric',
    'Desi Ghee',
    'Mustard Oil',
    'Chai Patti',
    'Sabudana',
    'Dishwash Bar',
  ];

  final List<String> _quickHindiSuggestions = [
    'गेहूं का आटा',
    'तूर दाल',
    'हल्दी',
    'देसी घी',
    'सरसों का तेल',
    'चाय पत्ती',
    'साबूदाना',
    'बर्तन साबुन',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _performTranslation(String query) {
    if (query.trim().isEmpty) {
      setState(() => _result = null);
      return;
    }
    final res = TranslationService.translate(query, isEngToHindi: _isEngToHindi);
    setState(() {
      _result = res;
    });
  }

  void _toggleDirection() {
    setState(() {
      _isEngToHindi = !_isEngToHindi;
      _inputController.clear();
      _result = null;
    });
  }

  void _openItemSheet() {
    if (_result?.matchedCatalogItem != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ItemDetailSheet(
          catalogItem: _result!.matchedCatalogItem!,
          onSave: (invItem) {
            widget.onItemAdded(invItem);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added "${invItem.customName}" to Pantry!')),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final suggestions = _isEngToHindi ? _quickEngSuggestions : _quickHindiSuggestions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilingual Grocery Translator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Direction Switcher Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEngToHindi ? 'English ➔ Hindi (हिंदी)' : 'Hindi (हिंदी) ➔ English',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, color: Colors.orangeAccent),
                    onPressed: _toggleDirection,
                    tooltip: 'Switch Language Direction',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Input Field
            ShadInput(
              controller: _inputController,
              placeholder: Text(
                _isEngToHindi
                    ? 'Type in English e.g. "Toor Dal", "Turmeric"...'
                    : 'Type in Hindi e.g. "तूर दाल", "हल्दी"...',
              ),
              leading: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.translate, size: 20, color: Colors.orangeAccent),
              ),
              trailing: _inputController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _inputController.clear();
                        _performTranslation('');
                      },
                    )
                  : null,
              onChanged: _performTranslation,
            ),
            const SizedBox(height: 16),
            const Text(
              'Quick Try Suggestions:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: suggestions.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    _inputController.text = s;
                    _performTranslation(s);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Translation Result Card
            if (_result != null && _result!.sourceText.isNotEmpty) ...[
              const Text(
                'Translation Result',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.amber.withValues(alpha: 0.5) : Colors.amber,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _result!.matchedCatalogItem?.iconEmoji ?? '🔤',
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _result!.translatedText,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'From: ${_result!.sourceText} (${_result!.sourceLanguage})',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_result!.category != null) ...[
                      const SizedBox(height: 12),
                      ShadBadge(
                        child: Text('Category: ${_result!.category}'),
                      ),
                    ],
                    if (_result!.aliases.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Regional Aliases: ${_result!.aliases.join(", ")}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                    if (_result!.matchedCatalogItem != null) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ShadButton(
                          onPressed: _openItemSheet,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_shopping_cart, size: 18),
                              SizedBox(width: 8),
                              Text('Add Item to Pantry Inventory'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
