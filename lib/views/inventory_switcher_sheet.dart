import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_list.dart';
import '../services/database_helper.dart';

class InventorySwitcherSheet extends StatefulWidget {
  final InventoryList activeList;
  final Function(InventoryList newList) onListSelected;

  const InventorySwitcherSheet({
    super.key,
    required this.activeList,
    required this.onListSelected,
  });

  @override
  State<InventorySwitcherSheet> createState() => _InventorySwitcherSheetState();
}

class _InventorySwitcherSheetState extends State<InventorySwitcherSheet> {
  List<InventoryList> _lists = [];
  bool _isLoading = true;

  final List<String> _emojiOptions = ['🏠', '🪔', '🎆', '🧹', '👶', '🛒', '💊', '🥳', '🥦', '☕'];

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final lists = await DatabaseHelper.instance.getAllInventories();
    setState(() {
      _lists = lists;
      _isLoading = false;
    });
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    String selectedEmoji = '📦';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Custom Inventory List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter List Name (e.g. Navratri, Party, Medicine):',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'List name...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Icon:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _emojiOptions.map((e) {
                      final isSelected = e == selectedEmoji;
                      return ChoiceChip(
                        label: Text(e, style: const TextStyle(fontSize: 20)),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setDialogState(() => selectedEmoji = e);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 15)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final newList = await DatabaseHelper.instance.createInventory(
                        name,
                        selectedEmoji,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        widget.onListSelected(newList);
                      }
                    }
                  },
                  child: const Text('Create List', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Inventory List / सूची चुनें',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0F172A), size: 26),
                onPressed: _showCreateDialog,
                tooltip: 'Create New Inventory List',
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _lists.length,
                itemBuilder: (context, index) {
                  final list = _lists[index];
                  final isSelected = list.id == widget.activeList.id;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    color: isSelected
                        ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                        : cardBgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF0F172A) : borderColor,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Text(list.iconEmoji, style: const TextStyle(fontSize: 32)),
                      title: Text(
                        list.name,
                        style: TextStyle(
                          fontSize: 17, // Large Font List Title
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      subtitle: list.isDefault
                          ? const Text('Primary Household Pantry', style: TextStyle(fontSize: 13, color: Colors.grey))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Color(0xFF0F172A), size: 24),
                          if (!list.isDefault && list.id != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 22),
                              onPressed: () async {
                                await DatabaseHelper.instance.deleteInventory(list.id!);
                                _loadLists();
                              },
                            ),
                        ],
                      ),
                      onTap: () {
                        widget.onListSelected(list);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ShadButton.outline(
              onPressed: _showCreateDialog,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '➕ Create New Inventory List (Pooja, Festival...)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
