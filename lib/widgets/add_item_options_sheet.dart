import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class AddItemOptionsSheet extends StatelessWidget {
  final String listName;
  final AppLanguage language;
  final VoidCallback onScanTap;
  final VoidCallback onAddFormTap;
  final VoidCallback onBrowseTap;

  const AddItemOptionsSheet({
    super.key,
    this.listName = '',
    this.language = AppLanguage.english,
    required this.onScanTap,
    required this.onAddFormTap,
    required this.onBrowseTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHindi = language == AppLanguage.hindi;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final displayListName = listName.isNotEmpty
        ? LocalizationService.getListName(listName, language)
        : (isHindi ? 'सूची' : 'List');

    final headerText = isHindi
        ? '$displayListName में सामान जोड़ें'
        : 'Add Item to $displayListName';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headerText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          _OptionRow(
            icon: Icons.camera_alt_outlined,
            title: isHindi ? 'फोटो स्कैन करें' : 'Scan Photo',
            subtitle: isHindi
                ? 'सामान की फोटो खींचें या स्कैन करें'
                : 'Take or scan images of the product',
            textColor: textColor,
            subtextColor: subtextColor,
            onTap: () {
              Navigator.pop(context);
              onScanTap();
            },
          ),
          const SizedBox(height: 18),
          Divider(color: dividerColor, thickness: 1),
          const SizedBox(height: 18),
          _OptionRow(
            icon: Icons.edit_note,
            title: isHindi ? 'फॉर्म भरें' : 'Add Item Form',
            subtitle: isHindi
                ? 'मैन्युअल रूप से विवरण भरें'
                : 'Fill form manually with optional photo',
            textColor: textColor,
            subtextColor: subtextColor,
            onTap: () {
              Navigator.pop(context);
              onAddFormTap();
            },
          ),
          const SizedBox(height: 18),
          Divider(color: dividerColor, thickness: 1),
          const SizedBox(height: 18),
          _OptionRow(
            icon: Icons.search,
            title: isHindi ? 'कलेक्शन देखें' : 'Browse Collection',
            subtitle: isHindi
                ? '200+ सामान की सूची में से चुनें'
                : 'Browse our collection of 200+ products',
            textColor: textColor,
            subtextColor: subtextColor,
            onTap: () {
              Navigator.pop(context);
              onBrowseTap();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color subtextColor;
  final VoidCallback onTap;

  const _OptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.subtextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFA7F3D0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF000000),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
