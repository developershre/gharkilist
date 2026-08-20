import 'package:flutter/material.dart';
import '../models/inventory_list.dart';
import '../services/localization_service.dart';

class InventoryTagBar extends StatelessWidget {
  final List<InventoryList> allLists;
  final InventoryList activeList;
  final AppLanguage language;
  final ValueChanged<InventoryList> onListSelected;

  const InventoryTagBar({
    super.key,
    required this.allLists,
    required this.activeList,
    this.language = AppLanguage.english,
    required this.onListSelected,
  });

  @override
  Widget build(BuildContext context) {
    final listsToDisplay = allLists.isNotEmpty ? allLists : [activeList];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: listsToDisplay.map((list) {
            final isSelected =
                activeList.id == list.id ||
                (activeList.id == null &&
                    activeList.name.toLowerCase() == list.name.toLowerCase());
            final displayName = LocalizationService.getListName(
              list.name,
              language,
            );

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _TagPill(
                label: displayName,
                isSelected: isSelected,
                onTap: () => onListSelected(list),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TagPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pillWidget = isSelected
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: pillWidget,
    );
  }
}
