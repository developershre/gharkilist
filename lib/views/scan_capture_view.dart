import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_item.dart';
import 'catalog_browse_view.dart';

class ScanCaptureView extends StatefulWidget {
  final Function(InventoryItem item) onItemAdded;

  const ScanCaptureView({
    super.key,
    required this.onItemAdded,
  });

  @override
  State<ScanCaptureView> createState() => _ScanCaptureViewState();
}

class _ScanCaptureViewState extends State<ScanCaptureView> {
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;

  Future<void> _capturePhoto(ImageSource source) async {
    setState(() => _isCapturing = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      setState(() => _isCapturing = false);

      if (photo != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CatalogBrowseView(
              capturedPhotoPath: photo.path,
              onItemAdded: (item) {
                widget.onItemAdded(item);
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Package / Bag (Pre-AI)'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_enhance_outlined,
                  size: 60,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pre-AI Photo Dataset Builder',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Take a photo of your staple package or kirana bag. After capture, pick the item from our catalog to save & label the image for training.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 36),
              if (_isCapturing)
                const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ShadButton(
                    onPressed: () => _capturePhoto(ImageSource.camera),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 20),
                        SizedBox(width: 8),
                        Text('Take Photo with Camera'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ShadButton.outline(
                    onPressed: () => _capturePhoto(ImageSource.gallery),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, size: 20),
                        SizedBox(width: 8),
                        Text('Choose from Gallery'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
