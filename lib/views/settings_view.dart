import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_list.dart';
import '../services/database_helper.dart';

class SettingsView extends StatefulWidget {
  final InventoryList activeList;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onListCleared;

  const SettingsView({
    super.key,
    required this.activeList,
    required this.isDark,
    required this.onToggleTheme,
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
      setState(() {
        _itemCount = count;
        _isLoading = false;
      });
    }
  }

  void _showClearListConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Items in List?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to remove all $_itemCount items from "${widget.activeList.name}"? This action cannot be undone.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              onPressed: () async {
                final db = await DatabaseHelper.instance.database;
                await db.delete('inventory_items', where: 'inventory_id = ?', whereArgs: [widget.activeList.id]);
                if (mounted) {
                  Navigator.pop(context);
                  widget.onListCleared();
                  _loadStats();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cleared all items from "${widget.activeList.name}"')),
                  );
                }
              },
              child: const Text('Clear List', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('Settings (ऐप सेटिंग्स)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section 1: Appearance & Theme
          Text(
            'Appearance & Theme (दिखावट)',
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
              leading: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: isDark ? const Color(0xFFFACC15) : const Color(0xFF0F172A),
                size: 26,
              ),
              title: const Text('App Theme Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              subtitle: Text(
                isDark ? 'Dark Slate Mode Active' : 'Light Mode Active',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              trailing: Switch(
                value: isDark,
                onChanged: (val) => widget.onToggleTheme(),
                activeColor: const Color(0xFF38BDF8),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: WhatsApp Sharing Options
          Text(
            'WhatsApp Export Settings (व्हाट्सएप सेटिंग्स)',
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
              leading: const Icon(Icons.currency_rupee, color: Color(0xFF22C55E), size: 26),
              title: const Text('Include Prices in WhatsApp Message', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              subtitle: const Text('Include estimated budget when sharing list', style: TextStyle(fontSize: 13, color: Colors.grey)),
              trailing: Switch(
                value: _includePricesInWhatsApp,
                onChanged: (val) {
                  setState(() => _includePricesInWhatsApp = val);
                },
                activeColor: const Color(0xFF22C55E),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Storage & Active List Management
          Text(
            'Active List Storage & Cap Status',
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
                  leading: const Icon(Icons.delete_sweep, color: Color(0xFFEF4444), size: 24),
                  title: const Text('Clear Active List Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                  subtitle: const Text('Remove all items from this active list', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: _itemCount > 0 ? _showClearListConfirmation : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 4: About & Version Info
          Text(
            'About Bhandar Khata (ऐप जानकारी)',
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
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: Color(0xFF0EA5E9), size: 26),
                  title: Text('Bhandar Khata (भंडार खाता)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: Text('Household Pantry & Kirana Inventory Tracker for Indian Families', style: TextStyle(fontSize: 13)),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.verified, color: Color(0xFF22C55E), size: 22),
                  title: Text('Version', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  trailing: Text('v1.2.0 (Build 3)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
