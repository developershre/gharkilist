import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_list.dart';
import '../providers/app_inventory_provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';

class SettingsView extends StatefulWidget {
  final InventoryList activeList;
  final VoidCallback onOpenTranslator;
  final VoidCallback onListCleared;

  const SettingsView({
    super.key,
    required this.activeList,
    required this.onOpenTranslator,
    required this.onListCleared,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
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

  void _showClearListConfirmation(AppSettingsProvider settings, AppInventoryProvider inventory) {
    final isHindi = settings.isHindi;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isHindi ? 'सूची के सारे सामान हटाएं?' : 'Clear All Items in List?',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(
            isHindi
                ? 'क्या आप "${widget.activeList.name}" से सभी $_itemCount सामान हटाना चाहते हैं? यह क्रिया वापस नहीं ली जा सकती।'
                : 'Are you sure you want to remove all $_itemCount items from "${widget.activeList.name}"? This action cannot be undone.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                await inventory.clearActiveList();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                widget.onListCleared();
                _loadStats();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isHindi ? 'सूची के सारे सामान हट गए' : 'Cleared all items from list'),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
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
    final settings = context.watch<AppSettingsProvider>();
    final inventory = context.watch<AppInventoryProvider>();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHindi = settings.isHindi;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primaryGreen = const Color(0xFF00C853);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isHindi ? 'सेटिंग्स' : 'Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // Section 1: Appearance & Language
          _buildSectionHeader(isHindi ? 'दिखावट व भाषा' : 'Appearance & Language', subtextColor),
          const SizedBox(height: 6),
          _buildCardGroup(
            cardBgColor: cardBgColor,
            borderColor: borderColor,
            children: [
              // Theme selector row
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined, color: primaryGreen, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          isHindi ? 'थीम' : 'Theme',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSegmentButton(
                            label: isHindi ? 'सिस्टम' : 'System',
                            isSelected: settings.themeMode == ThemeMode.system,
                            onTap: () => settings.setThemeMode(ThemeMode.system),
                            primaryGreen: primaryGreen,
                            subtextColor: subtextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSegmentButton(
                            label: isHindi ? 'लाइट' : 'Light',
                            isSelected: settings.themeMode == ThemeMode.light,
                            onTap: () => settings.setThemeMode(ThemeMode.light),
                            primaryGreen: primaryGreen,
                            subtextColor: subtextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSegmentButton(
                            label: isHindi ? 'डार्क' : 'Dark',
                            isSelected: settings.themeMode == ThemeMode.dark,
                            onTap: () => settings.setThemeMode(ThemeMode.dark),
                            primaryGreen: primaryGreen,
                            subtextColor: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              // Language selector row
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language, color: primaryGreen, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          isHindi ? 'भाषा' : 'Language',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSegmentButton(
                            label: 'English',
                            isSelected: settings.language == AppLanguage.english,
                            onTap: () => settings.setLanguage(AppLanguage.english),
                            primaryGreen: primaryGreen,
                            subtextColor: subtextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSegmentButton(
                            label: 'हिंदी',
                            isSelected: settings.language == AppLanguage.hindi,
                            onTap: () => settings.setLanguage(AppLanguage.hindi),
                            primaryGreen: primaryGreen,
                            subtextColor: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Section 2: Preferences & Tools
          _buildSectionHeader(isHindi ? 'प्राथमिकताएं व टूल' : 'Preferences & Tools', subtextColor),
          const SizedBox(height: 6),
          _buildCardGroup(
            cardBgColor: cardBgColor,
            borderColor: borderColor,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: Icon(Icons.g_translate, color: primaryGreen, size: 22),
                title: Text(
                  isHindi ? 'हिंदी / English अनुवादक' : 'Translator Tool',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                ),
                subtitle: Text(
                  isHindi ? 'किराना सामानों का नाम अनुवाद करें' : 'Translate Kirana item names',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
                trailing: Icon(Icons.chevron_right, color: subtextColor, size: 20),
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenTranslator();
                },
              ),
              Divider(height: 1, color: borderColor),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                secondary: Icon(Icons.currency_rupee, color: primaryGreen, size: 22),
                title: Text(
                  isHindi ? 'WhatsApp शेयर में दाम शामिल करें' : 'Include Prices in WhatsApp Share',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                ),
                value: settings.includePricesInWhatsApp,
                onChanged: (val) {
                  settings.setIncludePricesInWhatsApp(val);
                },
                activeThumbColor: primaryGreen,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Section 3: Data Management
          _buildSectionHeader(isHindi ? 'डेटा प्रबंधन' : 'Data Management', subtextColor),
          const SizedBox(height: 6),
          _buildCardGroup(
            cardBgColor: cardBgColor,
            borderColor: borderColor,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFEF4444), size: 24),
                title: Text(
                  isHindi ? 'सूची के सभी सामान हटाएं' : 'Clear All Items in List',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                ),
                subtitle: Text(
                  '${widget.activeList.name} (${_isLoading ? "..." : "$_itemCount"} ${isHindi ? "सामान" : "items"})',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
                trailing: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.chevron_right, color: subtextColor, size: 20),
                onTap: _itemCount > 0 ? () => _showClearListConfirmation(settings, inventory) : null,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Footer info
          Center(
            child: Column(
              children: [
                Text(
                  'Gharkilist v1.0.0',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subtextColor),
                ),
                const SizedBox(height: 2),
                Text(
                  isHindi ? '100% ऑफ़लाइन व सुरक्षित' : '100% Private & Offline',
                  style: TextStyle(fontSize: 11, color: subtextColor.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildCardGroup({
    required Color cardBgColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryGreen,
    required Color subtextColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryGreen : subtextColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : subtextColor,
          ),
        ),
      ),
    );
  }
}
