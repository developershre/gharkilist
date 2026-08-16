import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_item.dart';
import '../services/localization_service.dart';
import 'add_item_form_view.dart';

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
  bool _isProcessing = false;

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        _capturedFile = photo;
        _isProcessing = true;
      });

      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _navigateToFormWithPhoto(photo.path);
      }
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
      ),
      body: Padding(
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
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 64,
                              color: Color(0xFF0EA5E9),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isHindi ? 'सामान की फोटो लें' : 'Scan Item Photo',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              isHindi
                                  ? 'सामान या किराना थैले की फोटो खींचकर अपनी सूची में सहेजें!'
                                  : 'Take a photo of any grocery packet or Kirana bag to save it in your inventory!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isProcessing)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    isHindi ? 'चित्र प्रोसेस हो रहा है...' : 'Processing image...',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ShadButton.outline(
                        onPressed: _pickFromGallery,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_library, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isHindi ? 'गैलरी' : 'Gallery',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.camera_alt, size: 22),
                        label: Text(
                          isHindi ? 'फोटो खींचें' : 'Take Photo',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: _takePhoto,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
