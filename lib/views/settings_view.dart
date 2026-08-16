import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_list.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';

class SettingsView extends StatefulWidget {
  final InventoryList activeList;
  final ThemeMode themeMode;
  final AppLanguage language;
  final Function(ThemeMode mode) onSetThemeMode;
  final Function(AppLanguage language) onSetLanguage;
  final VoidCallback onOpenTranslator;
  final VoidCallback onListCleared;

  const SettingsView({
    super.key,
    required this.activeList,
    required this.themeMode,
    required this.language,
    required this.onSetThemeMode,
    required this.onSetLanguage,
    required this.onOpenTranslator,
    required this.onListCleared,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _includePricesInWhatsApp = true;
  int _itemCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (widget.activeList.id != null) {
      final count = await DatabaseHelper.instance.getInventoryCountForList(widget.activeList.id!);
      if (mounted) {
        setState(() {
          _itemCount = count;
          _isLoading = false;
        });
      }
    }
  }

  void _showClearListConfirmation() {
    final isHindi = widget.language == AppLanguage.hindi;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isHindi ? 'सूची के सारे सामान हटाएं?' : 'Clear All Items in List?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text(
            isHindi
                ? 'क्या आप "${widget.activeList.name}" से सभी $_itemCount सामान हटाना चाहते हैं?'
                : 'Are you sure you want to remove all $_itemCount items from "${widget.activeList.name}"?',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              onPressed: () async {
                final db = await DatabaseHelper.instance.database;
                await db.delete('inventory_items', where: 'inventory_id = ?', whereArgs: [widget.activeList.id]);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                widget.onListCleared();
                _loadStats();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isHindi ? 'सूची के सारे सामान हट गए' : 'Cleared all items from list')),
                  );
                }
              },
              child: Text(isHindi ? 'हटाएं' : 'Clear List', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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
          isHindi ? 'ऐप सेटिंग्स' : 'Settings',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section 1: App Theme (Default: System Theme)
          Text(
            isHindi ? 'दिखावट थीम' : 'App Theme',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        isHindi ? 'थीम चुनें' : 'Select Theme',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildThemeSegment(
                          label: isHindi ? 'सिस्टम' : 'System',
                          mode: ThemeMode.system,
                          isSelected: widget.themeMode == ThemeMode.system,
                          activeColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeSegment(
                          label: isHindi ? 'लाइट' : 'Light',
                          mode: ThemeMode.light,
                          isSelected: widget.themeMode == ThemeMode.light,
                          activeColor: const Color(0xFF0EA5E9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeSegment(
                          label: isHindi ? 'डार्क' : 'Dark',
                          mode: ThemeMode.dark,
                          isSelected: widget.themeMode == ThemeMode.dark,
                          activeColor: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Global App Language (Default: English)
          Text(
            isHindi ? 'भाषा' : 'Language',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.language, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        isHindi ? 'भाषा चुनें' : 'Select Language',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLangSegment(
                          label: 'English',
                          language: AppLanguage.english,
                          isSelected: widget.language == AppLanguage.english,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildLangSegment(
                          label: 'हिंदी (Hindi)',
                          language: AppLanguage.hindi,
                          isSelected: widget.language == AppLanguage.hindi,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Translator Tool Integration
          Text(
            isHindi ? 'अनुवादक (Translator Tool)' : 'Translator Tool',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(Icons.g_translate, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), size: 26),
              title: Text(
                isHindi ? 'हिंदी / English अनुवादक' : 'Hindi / English Translator',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isHindi ? 'सामान का अनुवाद और खोजें' : 'Translate and convert item names',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              trailing: Icon(Icons.chevron_right, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenTranslator();
              },
            ),
          ),
          const SizedBox(height: 24),

          // Section 4: WhatsApp Export Settings
          Text(
            isHindi ? 'व्हाट्सएप सेटिंग्स' : 'WhatsApp Export Settings',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(Icons.currency_rupee, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF22C55E), size: 26),
              title: Text(
                isHindi ? 'व्हाट्सएप में दाम दिखाएं' : 'Include Prices in WhatsApp',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isHindi ? 'अनुमानित कुल खर्च मैसेज में जोड़ें' : 'Include estimated total budget',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              trailing: Switch(
                value: _includePricesInWhatsApp,
                onChanged: (val) {
                  setState(() => _includePricesInWhatsApp = val);
                },
                activeThumbColor: const Color(0xFF22C55E),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 5: Storage & Active List Management
          Text(
            isHindi ? 'सूची जानकारी' : 'List Storage Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Text(widget.activeList.iconEmoji, style: const TextStyle(fontSize: 28)),
                  title: Text(widget.activeList.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: _isLoading
                      ? const Text('Loading items...')
                      : Text('$_itemCount / ${DatabaseHelper.freeTierCap} items tracked', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  trailing: ShadBadge(
                    child: Text('$_itemCount Items'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_sweep, color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444), size: 24),
                  title: Text(
                    isHindi ? 'सूची के सारे सामान हटाएं' : 'Clear Active List Items',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444)),
                  ),
                  subtitle: Text(
                    isHindi ? 'इस सूची से सभी सामान हटाएं' : 'Remove all items from this list',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: _itemCount > 0 ? _showClearListConfirmation : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 6: About & Version Info (Official Production v1.0.0)
          Text(
            isHindi ? 'ऐप जानकारी' : 'About Bhandar Khata',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.inventory_2_outlined, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9), size: 26),
                  title: const Text('Bhandar Khata (भंडार खाता)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                    'Smart Household Pantry & Kirana Inventory Tracker for Indian Families',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.lock_outline, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), size: 22),
                  title: Text(isHindi ? 'गोपनीयता (Privacy)' : 'Data Privacy', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    isHindi ? '100% ऑफ़लाइन व सुरक्षित - आपका डाटा सिर्फ आपके फोन पर है' : '100% Offline & Private - All data stays on your phone',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.verified, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF22C55E), size: 22),
                  title: const Text('Version', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  trailing: Text(
                    'v1.0.0 (Release Build)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSegment({
    required String label,
    required ThemeMode mode,
    required bool isSelected,
    required Color activeColor,
  }) {
    return InkWell(
      onTap: () => widget.onSetThemeMode(mode),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildLangSegment({
    required String label,
    required AppLanguage language,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => widget.onSetLanguage(language),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
