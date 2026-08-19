import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_item.dart';
import '../providers/app_inventory_provider.dart';
import '../services/localization_service.dart';
import 'add_item_form_view.dart';
import 'settings_view.dart';
import '../widgets/svg_icon.dart';
import 'translator_view.dart';

class ScanCaptureView extends StatefulWidget {
  final int inventoryId;
  final AppLanguage language;
  final Function(InventoryItem item)? onItemAdded;
  final VoidCallback? onRefresh;

  const ScanCaptureView({
    super.key,
    this.inventoryId = 1,
    this.language = AppLanguage.english,
    this.onItemAdded,
    this.onRefresh,
  });

  @override
  State<ScanCaptureView> createState() => _ScanCaptureViewState();
}

class _ScanCaptureViewState extends State<ScanCaptureView> {
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedFile;

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        _capturedFile = photo;
      });
      _navigateToFormWithPhoto(photo.path);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        _capturedFile = photo;
      });
      _navigateToFormWithPhoto(photo.path);
    }
  }

  void _navigateToFormWithPhoto(String photoPath) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemFormView(
          inventoryId: widget.inventoryId,
          language: widget.language,
          initialPhotoPath: photoPath,
          onItemAdded: () {
            widget.onRefresh?.call();
          },
        ),
      ),
    );
  }

  void _openSettingsView() {
    final inventory = context.read<AppInventoryProvider>();
    if (inventory.activeList == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsView(
          activeList: inventory.activeList!,
          onOpenTranslator: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TranslatorView(
                  onItemAdded: (item) => inventory.addInventoryItem(item),
                ),
              ),
            );
          },
          onListCleared: () => inventory.clearActiveList(),
        ),
      ),
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
          isHindi ? 'कैमरा स्कैन' : 'Camera Scan',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: SvgIcon('settings', color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B), size: 26),
            tooltip: isHindi ? 'सेटिंग्स' : 'Settings',
            onPressed: _openSettingsView,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: _capturedFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(_capturedFile!.path),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const SvgIcon(
                              'camera',
                              size: 64,
                              color: Color(0xFF0EA5E9),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isHindi ? 'सामान का फोटो खीचें' : 'Take a photo of your item',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isHindi
                                ? 'पैकेट या सामान की फोटो लेकर जोड़ें'
                                : 'Snap a picture of the product or receipt',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    height: 52,
                    onPressed: _pickFromGallery,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SvgIcon('photo_library', size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isHindi ? 'गैलरी से चुनें' : 'Gallery',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ShadButton(
                    height: 52,
                    backgroundColor: const Color(0xFF0EA5E9),
                    onPressed: _takePhoto,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SvgIcon('camera', size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          isHindi ? 'फोटो लें' : 'Take Photo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
     ),
    );
  }
}
