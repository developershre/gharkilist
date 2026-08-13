import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inventory_item.dart';
import 'localization_service.dart';

class ShareService {
  static String formatGroceryList(
    List<InventoryItem> items, {
    String listName = 'रसोई का सामान',
    AppLanguage language = AppLanguage.hindi,
  }) {
    final cleanListName = listName.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim();

    if (items.isEmpty) {
      return language == AppLanguage.hindi
          ? '🛒 *सामान की सूची ($cleanListName)*\n\nसूची अभी खाली है!'
          : '🛒 *Grocery List ($cleanListName)*\n\nList is currently empty!';
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

    final buffer = StringBuffer();
    if (language == AppLanguage.hindi) {
      buffer.writeln('🛒 *सामान की सूची ($cleanListName):*\n');

      if (outItems.isNotEmpty) {
        buffer.writeln('🔴 *खत्म (Bring these):*');
        for (final item in outItems) {
          final name = LocalizationService.getItemName(item.customName, item.nameHi, AppLanguage.hindi);
          final qtyStr = _formatQuantity(item.quantity, item.unit);
          final priceStr = item.estimatedPrice != null && item.estimatedPrice! > 0
              ? ' (~₹${(item.quantity * item.estimatedPrice!).toInt()})'
              : '';
          buffer.writeln('• $name - *$qtyStr*$priceStr');
        }
      }

      if (lowItems.isNotEmpty) {
        if (outItems.isNotEmpty) buffer.writeln();
        buffer.writeln('⚠️ *कम है (Running low):*');
        for (final item in lowItems) {
          final name = LocalizationService.getItemName(item.customName, item.nameHi, AppLanguage.hindi);
          final qtyStr = _formatQuantity(item.quantity, item.unit);
          final priceStr = item.estimatedPrice != null && item.estimatedPrice! > 0
              ? ' (~₹${(item.quantity * item.estimatedPrice!).toInt()})'
              : '';
          buffer.writeln('• $name - *$qtyStr*$priceStr');
        }
      }

      if (regularItems.isNotEmpty) {
        if (outItems.isNotEmpty || lowItems.isNotEmpty) {
          buffer.writeln('\n📦 *अन्य सामान:*');
        }
        for (final item in regularItems) {
          final name = LocalizationService.getItemName(item.customName, item.nameHi, AppLanguage.hindi);
          final qtyStr = _formatQuantity(item.quantity, item.unit);
          final priceStr = item.estimatedPrice != null && item.estimatedPrice! > 0
              ? ' (~₹${(item.quantity * item.estimatedPrice!).toInt()})'
              : '';
          buffer.writeln('• $name - *$qtyStr*$priceStr');
        }
      }

      if (totalEstimatedCost > 0) {
        buffer.writeln('\n💰 *कुल अनुमानित खर्च:* ₹${totalEstimatedCost.toInt()}');
      }
    } else {
      buffer.writeln('🛒 *Grocery List ($cleanListName):*\n');

      if (outItems.isNotEmpty) {
        buffer.writeln('🔴 *Out of Stock:*');
        for (final item in outItems) {
          final name = LocalizationService.getItemName(item.customName, item.nameHi, AppLanguage.english);
          final qtyStr = _formatQuantity(item.quantity, item.unit);
          final priceStr = item.estimatedPrice != null && item.estimatedPrice! > 0
              ? ' (~₹${(item.quantity * item.estimatedPrice!).toInt()})'
              : '';
          buffer.writeln('• $name - *$qtyStr*$priceStr');
        }
      }

      if (lowItems.isNotEmpty) {
        if (outItems.isNotEmpty) buffer.writeln();
        buffer.writeln('⚠️ *Running Low:*');
        for (final item in lowItems) {
          final name = LocalizationService.getItemName(item.customName, item.nameHi, AppLanguage.english);
          final qtyStr = _formatQuantity(item.quantity, item.unit);
          final priceStr = item.estimatedPrice != null && item.estimatedPrice! > 0
              ? ' (~₹${(item.quantity * item.estimatedPrice!).toInt()})'
              : '';
          buffer.writeln('• $name - *$qtyStr*$priceStr');
        }
      }

      if (regularItems.isNotEmpty) {
        if (outItems.isNotEmpty || lowItems.isNotEmpty) {
          buffer.writeln('\n📦 *Other Items:*');
        }
        for (final item in regularItems) {
          final name = LocalizationService.getItemName(item.customName, item.nameHi, AppLanguage.english);
          final qtyStr = _formatQuantity(item.quantity, item.unit);
          final priceStr = item.estimatedPrice != null && item.estimatedPrice! > 0
              ? ' (~₹${(item.quantity * item.estimatedPrice!).toInt()})'
              : '';
          buffer.writeln('• $name - *$qtyStr*$priceStr');
        }
      }

      if (totalEstimatedCost > 0) {
        buffer.writeln('\n💰 *Estimated Total Budget:* ₹${totalEstimatedCost.toInt()}');
      }
    }

    return buffer.toString().trim();
  }

  static String _formatQuantity(double qty, String unit) {
    if (qty <= 0) return unit;
    final formattedQty = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
    return '$formattedQty $unit';
  }

  static Future<void> shareToWhatsApp(
    List<InventoryItem> items, {
    String listName = 'रसोई का सामान',
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
    String listName = 'रसोई का सामान',
    AppLanguage language = AppLanguage.hindi,
  }) async {
    final text = formatGroceryList(items, listName: listName, language: language);
    await Clipboard.setData(ClipboardData(text: text));
  }
}
