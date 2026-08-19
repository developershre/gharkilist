import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inventory_list.dart';
import '../providers/app_inventory_provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import '../widgets/svg_icon.dart';

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

  Future<void> _exportBackup(AppSettingsProvider settings) async {
    final isHindi = settings.isHindi;
    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper.instance;
      final lists = await db.getAllInventories();
      final items = await db.getAllInventoryItemsAcrossAllLists();

      final List<Map<String, dynamic>> listsJson = [];
      for (final list in lists) {
        final listItems = items.where((ii) => ii.inventoryId == list.id).toList();
        listsJson.add({
          'name': list.name,
          'icon_emoji': list.iconEmoji,
          'is_default': list.isDefault ? 1 : 0,
          'created_at': list.createdAt.toIso8601String(),
          'items': listItems.map((ii) => {
            'catalog_id': ii.catalogId,
            'custom_name': ii.customName,
            'name_hi': ii.nameHi,
            'category': ii.category,
            'quantity': ii.quantity,
            'unit': ii.unit,
            'estimated_price': ii.estimatedPrice,
            'display_order': ii.displayOrder,
            'is_low': ii.isLow ? 1 : 0,
            'is_out': ii.isOut ? 1 : 0,
            'captured_photo_path': ii.capturedPhotoPath,
            'updated_at': ii.updatedAt.toIso8601String(),
          }).toList(),
        });
      }

      final backupData = {
        'app': 'gharkilist',
        'version': 2,
        'exported_at': DateTime.now().toIso8601String(),
        'lists': listsJson,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/gharkilist_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await backupFile.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: isHindi ? 'घर की लिस्ट बैकअप' : 'Gharkilist Data Backup',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isHindi ? 'बैकअप निर्यात विफल: $e' : 'Export backup failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _importBackup(AppSettingsProvider settings, AppInventoryProvider inventory) async {
    final isHindi = settings.isHindi;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      setState(() => _isLoading = true);

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      final Map<String, dynamic> backupData = json.decode(content);

      if (backupData['app'] != 'gharkilist' || backupData['lists'] == null) {
        throw Exception(isHindi ? 'अमान्य बैकअप फ़ाइल फ़ॉर्मेट' : 'Invalid backup file format.');
      }

      final List<dynamic> lists = backupData['lists'];
      int totalItems = 0;
      for (final l in lists) {
        final List<dynamic> items = l['items'] ?? [];
        totalItems += items.length;
      }

      if (mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isHindi ? 'बैकअप रीस्टोर करें?' : 'Restore Backup?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Text(
                isHindi
                    ? 'यह बैकअप फ़ाइल ${lists.length} लिस्ट और $totalItems सामान जोड़ेगी। क्या आप जारी रखना चाहते हैं?'
                    : 'This backup file will add ${lists.length} lists with $totalItems items. Do you want to continue?',
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(isHindi ? 'जारी रखें' : 'Continue', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );

        if (confirm == true) {
          await DatabaseHelper.instance.importBackupData(lists);
          await inventory.preloadData();
          await _loadStats();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isHindi ? 'सफलतापूर्वक रीस्टोर किया गया!' : 'Successfully restored backup!',
                ),
                backgroundColor: const Color(0xFF00C853),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHindi ? 'बैकअप आयात विफल: $e' : 'Import backup failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
      body: SafeArea(
        child: ListView(
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
                        SvgIcon('palette', color: primaryGreen, size: 16),
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
                        SvgIcon('translate', color: primaryGreen, size: 16),
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
                leading: SvgIcon('translate', color: primaryGreen, size: 18),
                title: Text(
                  isHindi ? 'हिंदी / English अनुवादक' : 'Translator Tool',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                ),
                subtitle: Text(
                  isHindi ? 'किराना सामानों का नाम अनुवाद करें' : 'Translate Kirana item names',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
                trailing: SvgIcon('chevron_right', color: subtextColor, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenTranslator();
                },
              ),
              Divider(height: 1, color: borderColor),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                secondary: SvgIcon('money', color: primaryGreen, size: 18),
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
                leading: const SvgIcon('delete', color: Color(0xFFEF4444), size: 20),
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
                    : SvgIcon('chevron_right', color: subtextColor, size: 16),
                onTap: _itemCount > 0 ? () => _showClearListConfirmation(settings, inventory) : null,
              ),
              Divider(height: 1, color: borderColor),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: SvgIcon('backup', color: primaryGreen, size: 20),
                title: Text(
                  isHindi ? 'बैकअप निर्यात करें (Export)' : 'Export Backup',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                ),
                subtitle: Text(
                  isHindi ? 'सभी लिस्ट और सामानों का बैकअप फाइल बनाएं' : 'Export all lists and items to a JSON file',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
                trailing: SvgIcon('chevron_right', color: subtextColor, size: 16),
                onTap: _isLoading ? null : () => _exportBackup(settings),
              ),
              Divider(height: 1, color: borderColor),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: SvgIcon('restore', color: primaryGreen, size: 20),
                title: Text(
                  isHindi ? 'बैकअप आयात करें (Import)' : 'Import Backup',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                ),
                subtitle: Text(
                  isHindi ? 'पुरानी बैकअप फाइल से रीस्टोर करें' : 'Import lists and items from a JSON file',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
                trailing: SvgIcon('chevron_right', color: subtextColor, size: 16),
                onTap: _isLoading ? null : () => _importBackup(settings, inventory),
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
