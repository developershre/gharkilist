import 'package:flutter/material.dart';
import '../data/indian_pantry_catalog.dart';
import '../models/catalog_item.dart';
import '../models/inventory_list.dart';
import '../services/localization_service.dart';

class EmptyStateView extends StatelessWidget {
  final InventoryList activeList;
  final AppLanguage language;
  final VoidCallback onScanTap;
  final VoidCallback onBrowseTap;
  final Function(CatalogItem item) onQuickAddCatalogItem;

  const EmptyStateView({
    super.key,
    required this.activeList,
    required this.language,
    required this.onScanTap,
    required this.onBrowseTap,
    required this.onQuickAddCatalogItem,
  });

  void _showAddOptionsModal(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHindi = language == AppLanguage.hindi;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isHindi ? 'सामान जोड़ें: "${activeList.name}"' : 'Add Item to "${activeList.name}"',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isHindi ? 'अपनी सूची में नया सामान जोड़ने का तरीका चुनें' : 'Choose how to add items to your list',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0EA5E9)),
                ),
                title: Text(
                  isHindi ? 'फोटो खींचें (Camera Scan)' : 'Camera Scan',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  isHindi ? 'पैकेट या बोरी की फोटो लें' : 'Take a picture of item package',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  onScanTap();
                },
              ),
              const Divider(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.search_outlined, color: Color(0xFF6366F1)),
                ),
                title: Text(
                  isHindi ? 'सामान सूची देखें (Browse Catalog)' : 'Browse Catalog',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  isHindi ? 'आटा, दाल, मसाले, पूजा सामान खोजें' : 'Search 200+ Indian household staples',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  onBrowseTap();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHindi = language == AppLanguage.hindi;

    final quickStaples = seedIndianCatalog.where((i) => [
          'grains_atta',
          'grains_basmati_rice',
          'dal_toor',
          'spice_sugar',
          'dairy_milk_packet',
          'oil_ghee',
          'spice_salt',
          'spice_chai_patti'
        ].contains(i.id)).toList();

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // Active List Title Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Text(activeList.iconEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeList.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isHindi ? 'यह सूची अभी खाली है। सामान जोड़ने के लिए "+" दबाएं।' : 'This list is empty. Tap "+" to add items.',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Prominent Centered Dotted-Outline "+" List Card (Slate & White)
        GestureDetector(
          onTap: () => _showAddOptionsModal(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                width: 2.0,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(20),
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isHindi ? 'पहला सामान जोड़ें' : 'Add First Item to ${activeList.name}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isHindi ? 'फोटो खींचने या 200+ सामान देखने के लिए यहां दबाएं' : 'Tap here to Scan Photo or Browse Catalog',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // 1-Click Instant Add Section with Large Font Cards
        Text(
          isHindi ? '⚡ 1-क्लिक तुरंत जोड़ें:' : '⚡ 1-Click Quick Add Essentials:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: quickStaples.length,
          itemBuilder: (context, index) {
            final item = quickStaples[index];
            final itemName = LocalizationService.getItemName(item.nameEn, item.nameHi, language);

            return InkWell(
              onTap: () {
                onQuickAddCatalogItem(item);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added "$itemName" to ${activeList.name}!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Text(item.iconEmoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.add_circle,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                      size: 24,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
