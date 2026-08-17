import 'catalog_item.dart';

class InventoryItem {
  final int? id;
  final int inventoryId;
  final String catalogId;
  final String customName;
  final String nameHi;
  final String category;
  final double quantity;
  final String unit;
  final double? estimatedPrice;
  final int displayOrder;
  final bool isLow;
  final bool isOut;
  final String? capturedPhotoPath;
  final DateTime updatedAt;
  final CatalogItem? catalogItem;

  InventoryItem({
    this.id,
    this.inventoryId = 1,
    required this.catalogId,
    required this.customName,
    this.nameHi = '',
    required this.category,
    required this.quantity,
    required this.unit,
    this.estimatedPrice,
    this.displayOrder = 0,
    this.isLow = false,
    this.isOut = false,
    this.capturedPhotoPath,
    DateTime? updatedAt,
    this.catalogItem,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inventory_id': inventoryId,
      'catalog_id': catalogId,
      'custom_name': customName,
      'name_hi': nameHi,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'estimated_price': estimatedPrice,
      'display_order': displayOrder,
      'is_low': isLow ? 1 : 0,
      'is_out': isOut ? 1 : 0,
      'captured_photo_path': capturedPhotoPath,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map, {CatalogItem? catalogItem}) {
    return InventoryItem(
      id: map['id'] as int?,
      inventoryId: map['inventory_id'] as int? ?? 1,
      catalogId: map['catalog_id'] as String,
      customName: map['custom_name'] as String,
      nameHi: map['name_hi'] as String? ?? '',
      category: map['category'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      estimatedPrice: map['estimated_price'] != null ? (map['estimated_price'] as num).toDouble() : null,
      displayOrder: map['display_order'] as int? ?? 0,
      isLow: (map['is_low'] as int) == 1,
      isOut: (map['is_out'] as int) == 1,
      capturedPhotoPath: map['captured_photo_path'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      catalogItem: catalogItem,
    );
  }

  InventoryItem copyWith({
    int? id,
    int? inventoryId,
    String? catalogId,
    String? customName,
    String? nameHi,
    String? category,
    double? quantity,
    String? unit,
    double? estimatedPrice,
    int? displayOrder,
    bool? isLow,
    bool? isOut,
    String? capturedPhotoPath,
    DateTime? updatedAt,
    CatalogItem? catalogItem,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      catalogId: catalogId ?? this.catalogId,
      customName: customName ?? this.customName,
      nameHi: nameHi ?? this.nameHi,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      displayOrder: displayOrder ?? this.displayOrder,
      isLow: isLow ?? this.isLow,
      isOut: isOut ?? this.isOut,
      capturedPhotoPath: capturedPhotoPath ?? this.capturedPhotoPath,
      updatedAt: updatedAt ?? this.updatedAt,
      catalogItem: catalogItem ?? this.catalogItem,
    );
  }
}
