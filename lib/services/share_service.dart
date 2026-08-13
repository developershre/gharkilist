import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inventory_item.dart';

class ShareService {
  static String formatGroceryList(List<InventoryItem> items, {String listName = 'Household Pantry'}) {
    final titleUpper = listName.toUpperCase();

    if (items.isEmpty) {
      return '🛒 *BHANDAR KHATA - $titleUpper LIST*\n(घरेलू सामान की सूची)\n\nThis inventory list is currently empty!';
    }

    final outItems = items.where((i) => i.isOut).toList();
    final lowItems = items.where((i) => i.isLow && !i.isOut).toList();
    final regularItems = items.where((i) => !i.isLow && !i.isOut).toList();

    double totalEstimatedCost = 0.0;
    for (final item in items) {
      if (item.estimatedPrice != null && item.estimatedPrice! > 0) {
        totalEstimatedCost += item.quantity * item.estimatedPrice!;
      }
    }

    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final buffer = StringBuffer();
    buffer.writeln('🛒 *BHANDAR KHATA - $titleUpper LIST*');
    buffer.writeln('📋 *(घरेलू सामान की सूची)*');
    buffer.writeln('📅 *Date:* $dateStr');
    buffer.writeln('═════════════════════════');

    if (outItems.isNotEmpty) {
      buffer.writeln('\n🚨 *URGENT - OUT OF STOCK (खत्म हो गया):*');
      for (final item in outItems) {
        final hi = item.nameHi.isNotEmpty ? ' (${item.nameHi})' : '';
        final qtyStr = _formatQuantity(item.quantity, item.unit);
        final priceStr = item.estimatedPrice != null ? ' (~₹${(item.quantity * item.estimatedPrice!).toInt()})' : '';
        buffer.writeln('[ ] 🔴 *${item.customName}*$hi - *$qtyStr*$priceStr');
      }
    }

    if (lowItems.isNotEmpty) {
      buffer.writeln('\n⚠️ *RUNNING LOW (कम है - जल्द चाहिए):*');
      for (final item in lowItems) {
        final hi = item.nameHi.isNotEmpty ? ' (${item.nameHi})' : '';
        final qtyStr = _formatQuantity(item.quantity, item.unit);
        final priceStr = item.estimatedPrice != null ? ' (~₹${(item.quantity * item.estimatedPrice!).toInt()})' : '';
        buffer.writeln('[ ] 🟡 *${item.customName}*$hi - *$qtyStr*$priceStr');
      }
    }

    if (regularItems.isNotEmpty) {
      buffer.writeln('\n📦 *OTHER PANTRY ITEMS (स्टॉक में है):*');
      for (final item in regularItems) {
        final hi = item.nameHi.isNotEmpty ? ' (${item.nameHi})' : '';
        final qtyStr = _formatQuantity(item.quantity, item.unit);
        final priceStr = item.estimatedPrice != null ? ' (~₹${(item.quantity * item.estimatedPrice!).toInt()})' : '';
        buffer.writeln('[ ] 🟢 *${item.customName}*$hi - *$qtyStr*$priceStr');
      }
    }

    buffer.writeln('\n═════════════════════════');
    buffer.writeln('📋 *Total Listed Items:* ${items.length} items');
    if (totalEstimatedCost > 0) {
      buffer.writeln('💰 *Estimated Total Budget:* ₹${totalEstimatedCost.toInt()}');
    }
    buffer.writeln('🙏 Please confirm availability & delivery time.');
    buffer.writeln('\nShared via *Bhandar Khata App* 🌾');

    return buffer.toString();
  }

  static String _formatQuantity(double qty, String unit) {
    if (qty <= 0) return unit;
    final formattedQty = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
    return '$formattedQty $unit';
  }

  static Future<void> shareToWhatsApp(List<InventoryItem> items, {String listName = 'Household Pantry'}) async {
    final text = formatGroceryList(items, listName: listName);
    await Share.share(
      text,
      subject: 'Bhandar Khata - $listName',
    );
  }

  static Future<void> copyToClipboard(List<InventoryItem> items, {String listName = 'Household Pantry'}) async {
    final text = formatGroceryList(items, listName: listName);
    await Clipboard.setData(ClipboardData(text: text));
  }
}
