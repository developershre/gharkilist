import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inventory_item.dart';
import 'localization_service.dart';

class ShareService {
  static String formatGroceryList(
    List<InventoryItem> items, {
    String listName = 'Mahine ka',
    AppLanguage language = AppLanguage.hindi,
  }) {
    final displayListName = LocalizationService.getListName(listName, language);

    if (items.isEmpty) {
      return language == AppLanguage.hindi
          ? '🛒 *सामान की सूची ($displayListName)*\n\nसूची अभी खाली है!'
          : '🛒 *Grocery List ($displayListName)*\n\nList is currently empty!';
    }

    final sb = StringBuffer();
    if (language == AppLanguage.hindi) {
      sb.writeln('🛒 *घरेलू सामान सूची ($displayListName)*\n');
    } else {
      sb.writeln('🛒 *Household Grocery List ($displayListName)*\n');
    }

    double totalEstPrice = 0.0;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final name = item.catalogItem != null
          ? LocalizationService.getItemName(item.catalogItem!.nameEn, item.catalogItem!.nameHi, language)
          : LocalizationService.getItemName(item.customName, item.nameHi, language);

      final formattedQty = _formatQuantity(item.quantity, item.unit, language);
      sb.write('${i + 1}. $name - $formattedQty');

      if (item.estimatedPrice != null && item.estimatedPrice! > 0) {
        final itemTotal = item.quantity * item.estimatedPrice!;
        totalEstPrice += itemTotal;
        sb.write(' (₹${itemTotal.toInt()})');
      }
      sb.writeln();
    }

    if (totalEstPrice > 0) {
      sb.writeln('\n💰 *${language == AppLanguage.hindi ? 'अनुमानित कुल खर्च' : 'Estimated Total'}: ₹${totalEstPrice.toInt()}*');
    }

    sb.writeln(language == AppLanguage.hindi ? '\n_— घरकीलिस्ट_' : '\n_— Gharkilist_');
    return sb.toString();
  }

  static String _formatQuantity(double qty, String unit, AppLanguage language) {
    String formattedQty;
    if (qty % 1 == 0) {
      formattedQty = qty.toInt().toString();
    } else {
      formattedQty = qty.toStringAsFixed(1);
    }
    final unitLabel = LocalizationService.getUnitLabel(unit, language);
    return '$formattedQty $unitLabel';
  }

  static Future<void> shareToWhatsApp(
    List<InventoryItem> items, {
    String listName = 'Mahine ka',
    AppLanguage language = AppLanguage.hindi,
  }) async {
    final text = formatGroceryList(items, listName: listName, language: language);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: listName,
      ),
    );
  }

  static Future<void> copyToClipboard(
    List<InventoryItem> items, {
    String listName = 'Mahine ka',
    AppLanguage language = AppLanguage.hindi,
  }) async {
    final text = formatGroceryList(items, listName: listName, language: language);
    await Clipboard.setData(ClipboardData(text: text));
  }
}
