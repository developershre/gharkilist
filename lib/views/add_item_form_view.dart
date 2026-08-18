import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_item.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';

class AddItemFormView extends StatefulWidget {
  final int inventoryId;
  final AppLanguage language;
  final String? initialPhotoPath;
  final VoidCallback onItemAdded;

  const AddItemFormView({
    super.key,
    required this.inventoryId,
    this.language = AppLanguage.english,
    this.initialPhotoPath,
    required this.onItemAdded,
  });

  @override
  State<AddItemFormView> createState() => _AddItemFormViewState();
}

class _AddItemFormViewState extends State<AddItemFormView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController();

  String? _photoPath;
  String _selectedCategory = 'Flour & Grains';
  String _selectedUnit = 'PCS';
  String _stockStatus = 'In Stock';
  bool _isSaving = false;

  final List<String> _categories = [
    'Flour & Grains',
    'Oils & Ghee',
    'Spices & Masala',
    'Dairy & Bakery',
    'Snacks & Beverages',
    'Household',
    'Pooja Essentials',
    'Other',
  ];

  final List<String> _units = ['PCS', 'KG', 'G', 'L', 'ML', 'PKT', 'BOTTLE', 'CAN', 'BOX', 'STRIP', 'SACHET'];

  @override
  void initState() {
    super.initState();
    _photoPath = widget.initialPhotoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo != null) {
      setState(() {
        _photoPath = photo.path;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (photo != null) {
      setState(() {
        _photoPath = photo.path;
      });
    }
  }

  Future<void> _saveItem() async {
    final isHindi = widget.language == AppLanguage.hindi;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ShadToaster.of(context).show(
        ShadToast(
          title: Text(isHindi ? 'सामान का नाम आवश्यक है' : 'Item Name Required'),
          description: Text(isHindi ? 'कृपया सहेजने से पहले सामान का नाम दर्ज करें।' : 'Please enter an item name before saving.'),
        ),
      );
      return;
    }

    final qty = double.tryParse(_quantityController.text.trim()) ?? 1.0;
    final price = double.tryParse(_priceController.text.trim());

    setState(() => _isSaving = true);

    try {
      final newItem = InventoryItem(
        inventoryId: widget.inventoryId,
        catalogId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        customName: name,
        nameHi: name,
        category: _selectedCategory,
        quantity: qty,
        unit: LocalizationService.normalizeUnit(_selectedUnit),
        estimatedPrice: price,
        isLow: _stockStatus == 'Low Stock',
        isOut: _stockStatus == 'Out of Stock',
        capturedPhotoPath: _photoPath,
      );

      await DatabaseHelper.instance.addInventoryItem(newItem);
      widget.onItemAdded();

      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: Text(isHindi ? 'सामान सहेजा गया' : 'Item Saved'),
            description: Text(isHindi ? '"$name" सूची में जोड़ा गया।' : '"$name" added to inventory.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ShadToaster.of(context).show(
          ShadToast(
            title: Text(isHindi ? 'त्रुटि' : 'Error Saving Item'),
            description: Text(e.toString()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHindi = widget.language == AppLanguage.hindi;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final activeColor = const Color(0xFF00C853);

    final normalizedUnit = LocalizationService.normalizeUnit(_selectedUnit).toUpperCase();
    final safeUnitValue = _units.contains(normalizedUnit) ? normalizedUnit : _units.first;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBgColor,
        elevation: 0,
        title: Text(
          isHindi ? 'नया सामान जोड़ें' : 'Add Custom Item',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Header Box
            Text(
              isHindi ? 'सामान की फोटो' : 'Item Photo',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: _photoPath != null && File(_photoPath!).existsSync()
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_photoPath!),
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: InkWell(
                            onTap: () => setState(() => _photoPath = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 48, color: subtextColor),
                        const SizedBox(height: 10),
                        Text(
                          isHindi ? 'कोई फोटो नहीं चुनी गई' : 'No photo attached yet',
                          style: TextStyle(fontSize: 14, color: subtextColor),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _takePhoto,
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: Text(isHindi ? 'कैमरा' : 'Camera'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: activeColor,
                                side: BorderSide(color: activeColor),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _pickFromGallery,
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: Text(isHindi ? 'गैलरी' : 'Gallery'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: subtextColor,
                                side: BorderSide(color: borderColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            if (_photoPath != null && File(_photoPath!).existsSync()) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: Text(isHindi ? 'फिर से फोटो लें' : 'Retake Photo'),
                    style: TextButton.styleFrom(foregroundColor: activeColor),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Item Name Field
            Text(
              isHindi ? 'सामान का नाम *' : 'Item Name *',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: TextStyle(color: textColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: isHindi ? 'उदा. आटा 5 किग्रा, नमक...' : 'e.g. Aashirvaad Atta 5kg, Tata Salt...',
                hintStyle: TextStyle(color: subtextColor, fontSize: 15),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: cardBgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: activeColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Picker
            Text(
              isHindi ? 'श्रेणी (Category)' : 'Category',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((catKey) {
                final label = LocalizationService.getCategoryName(catKey, widget.language);
                final isSel = _selectedCategory == catKey;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSel,
                  selectedColor: activeColor,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : textColor,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    setState(() => _selectedCategory = catKey);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Quantity & Unit Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi ? 'मात्रा' : 'Quantity',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _quantityController,
                        style: TextStyle(color: textColor, fontSize: 16),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '1',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: cardBgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: activeColor, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi ? 'इकाई' : 'Unit',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: safeUnitValue,
                            isExpanded: true,
                            dropdownColor: cardBgColor,
                            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                            items: _units.map((u) {
                              final uLabel = LocalizationService.getUnitLabel(u.toLowerCase(), widget.language);
                              return DropdownMenuItem(value: u, child: Text(uLabel));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedUnit = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Estimated Price
            Text(
              isHindi ? 'अनुमानित कीमत (₹)' : 'Estimated Price (₹)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              style: TextStyle(color: textColor, fontSize: 16),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: isHindi ? 'उदा. 150' : 'e.g. 150',
                hintStyle: TextStyle(color: subtextColor, fontSize: 15),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: activeColor)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: cardBgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: activeColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stock Status ChoiceChips
            Text(
              isHindi ? 'स्टॉक स्थिति' : 'Stock Status',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['In Stock', 'Low Stock', 'Out of Stock'].map((stkKey) {
                final label = LocalizationService.getStatusLabel(stkKey, widget.language);
                final isSel = _stockStatus == stkKey;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSel,
                  selectedColor: activeColor,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : textColor,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    setState(() => _stockStatus = stkKey);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _saveItem,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            isHindi ? 'सूची में सहेजें' : 'Save to Inventory',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
     ),
    );
  }
}
