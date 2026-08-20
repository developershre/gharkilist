# 🛒 Gharkilist (घर की लिस्ट)

> **Smart Household Inventory & Grocery Tracker for Indian Families**

> 🧪 **Note**: This is the **first testing release (v1.0.0)** of Gharkilist! We would deeply appreciate any feedback, feature suggestions, or testing input.

**Gharkilist** is a modern, 100% offline, privacy-first mobile application built with Flutter. It solves the monthly grocery-list ritual for Indian households where standard barcode-based apps fail (loose *atta* in plastic bags, *dals* bought by weight, unbranded spices, and festival pooja supplies).

---

## ✨ Features

- **🏠 Curated Indian Pantry Catalog**:
  - Over 100+ pre-configured items tailored for Indian households across 8 categories (*Grains & Atta, Dals & Pulses, Spices & Masala, Dairy & Bakery, Oils & Ghee, Pooja Needs, Cleaning, Medicines*).
  - Bilingual item naming (English + Hindi/हिन्दी).

- **📲 One-Tap WhatsApp Kirana Export**:
  - Automatically formats item lists with quantities, estimated budget calculation (₹), and shares directly to WhatsApp for local kirana order placement.

- **🗂️ Multi-Inventory Switching**:
  - Manage multiple separate lists (e.g., *Kitchen Pantry, Monthly Kirana, Pooja Supplies, Party/Festive List*) or create custom lists.

- **✏️ Bottom Popup Edit Container**:
  - Interactive bottom sheet container with quantity stepper (`-` / `+`), numeric input, unit selector (`KG`, `G`, `L`, `ML`, `PCS`, `PKT`), custom naming, and estimated pricing.

- **🗑️ Delete & Undo Safety**:
  - One-tap red delete trash icon, swipe-to-delete gesture (`Dismissible`), deletion confirmation dialogs, and instant **Undo** SnackBar recovery.

- **🌐 Bilingual UI (English & हिन्दी)**:
  - Toggle the entire app interface instantly between English and Hindi.

- **🔒 100% Offline & Private**:
  - Powered by local SQLite database (`sqflite`). Zero tracking, zero account required, 100% local data storage.

- **⚡ Optimized & Lightweight**:
  - WebP asset compression (89% asset size reduction), R8 minification, resource shrinking, and fast cold-start performance.

---

## 🏗️ Project Architecture

```
lib/
├── data/
│   └── indian_pantry_catalog.dart   # Pre-filled catalog data for Indian groceries
├── models/
│   ├── catalog_item.dart            # Catalog item model schema
│   ├── inventory_item.dart          # Saved user inventory item model schema
│   └── inventory_list.dart          # Multi-inventory container model schema
├── services/
│   ├── database_helper.dart         # Local SQLite DB helper (sqflite)
│   ├── localization_service.dart     # English/Hindi translation mappings
│   └── share_service.dart            # WhatsApp text formatting & sharing
├── views/
│   ├── add_item_form_view.dart      # Custom item addition form
│   ├── catalog_browse_view.dart     # Full category & catalog browser view
│   ├── inventory_home_view.dart     # Main dashboard with reorderable list
│   ├── inventory_switcher_sheet.dart# Bottom sheet to switch & manage lists
│   ├── item_detail_sheet.dart       # Bottom popup edit container
│   ├── scan_capture_view.dart       # Photo capture view
│   ├── settings_view.dart           # App settings & theme/language controls
│   └── translator_view.dart         # Quick Hindi/English translator assistant
└── widgets/
    ├── empty_inventory_placeholder.dart
    ├── gharkilist_logo.dart         # Custom painted brand logo
    ├── inventory_filter_sheet.dart  # Filter items by category & stock status
    ├── inventory_item_tile.dart     # Redesigned item card widget
    ├── inventory_search_bar.dart    # Real-time search bar
    ├── inventory_tag_bar.dart       # Inventory switching pill bar
    └── item_icon_widget.dart        # Asset/Vector icon rendering widget
```

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: [Flutter](https://flutter.dev/) (Dart SDK `^3.12.2`)
- **Database**: [sqflite](https://pub.dev/packages/sqflite) (Local SQLite)
- **UI & Theme**: [shadcn_ui](https://pub.dev/packages/shadcn_ui), [google_fonts](https://pub.dev/packages/google_fonts), [font_awesome_flutter](https://pub.dev/packages/font_awesome_flutter)
- **Sharing**: [share_plus](https://pub.dev/packages/share_plus)
- **Hardware/Media**: [image_picker](https://pub.dev/packages/image_picker), [flutter_svg](https://pub.dev/packages/flutter_svg)

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.12.0`)
- Android Studio / Xcode

### Setup & Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/gharkilist.git
   cd gharkilist
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run static analysis & tests**:
   ```bash
   flutter analyze
   flutter test
   ```

4. **Run on connected device/emulator**:
   ```bash
   flutter run
   ```

5. **Build optimized release APK**:
   ```bash
   flutter build apk --obfuscate --split-debug-info=build/symbols
   ```

---

## 📄 License

This project is licensed under the MIT License.
