import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_list.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';

class InventorySwitcherSheet extends StatefulWidget {
  final InventoryList activeList;
  final AppLanguage language;
  final Function(InventoryList newList) onListSelected;

  const InventorySwitcherSheet({
    super.key,
    required this.activeList,
    this.language = AppLanguage.english,
    required this.onListSelected,
  });

  @override
  State<InventorySwitcherSheet> createState() => _InventorySwitcherSheetState();
}

class _InventorySwitcherSheetState extends State<InventorySwitcherSheet> {
  List<InventoryList> _lists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final lists = await DatabaseHelper.instance.getAllInventories();
    if (mounted) {
      setState(() {
        _lists = lists;
        _isLoading = false;
      });
    }
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final isHindi = widget.language == AppLanguage.hindi;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isHindi ? 'नई सूची बनाएं' : 'Create Custom Inventory List', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isHindi ? 'सूची का नाम लिखें (जैसे त्यौहार, पूजा, दवायां):' : 'Enter List Name (e.g. Navratri, Party, Medicine):',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: isHindi ? 'सूची का नाम...' : 'List name...',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isHindi ? 'रद्द करें' : 'Cancel', style: const TextStyle(fontSize: 15)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final newList = await DatabaseHelper.instance.createInventory(
                    name,
                    '',
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    widget.onListSelected(newList);
                  }
                }
              },
              child: Text(isHindi ? 'बनाएं' : 'Create List', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
              Expanded(
                child: Text(
                  isHindi ? 'सूची बदलें (Select Inventory List)' : 'Select Inventory List',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A), size: 26),
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
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected
                            ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A))
                            : borderColor,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          list.name.isNotEmpty ? list.name[0].toUpperCase() : 'L',
                          style: const TextStyle(
                            color: Color(0xFF00C853),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      title: Text(
                        list.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      subtitle: list.isDefault
                          ? Text(isHindi ? 'मुख्य घरेलू सूची' : 'Primary Household Pantry', style: const TextStyle(fontSize: 13, color: Colors.grey))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Icon(Icons.check_circle, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A), size: 24),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isHindi ? 'नई सूची बनाएं (Pooja, Festival...)' : 'Create New Inventory List (Pooja, Festival...)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
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

