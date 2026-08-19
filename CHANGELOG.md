# Changelog

All notable changes to the **Gharkilist (घर की लिस्ट)** application will be documented in this file. This project adheres to [Semantic Versioning](https://semver.org/).

---

## [1.0.5] - 2026-08-19
### Android Icon Standardisation & Build Output Cleanup
This release refactors the Android launcher icon configurations to align with native Android guidelines and ensures compiled build outputs are properly ignored.

#### Changed / Optimized
- **Android Launcher Icons**: Configured the launcher icon generator to use the standard `ic_launcher` name (instead of `launcher_icon`), resolving adaptive and monochrome icon warning issues.
- **AndroidManifest Configuration**: Updated `android/app/src/main/AndroidManifest.xml` to point to the new `@mipmap/ic_launcher` asset.
- **Build Ignorance**: Updated `.gitignore` to exclude the `output/` directory, preventing compiled APK files from being tracked in the repository.

---

## [1.0.0] - 2026-08-19
### First Stable Testing Release
This release compiles all development iterations into a polished testing build, introducing list management extensions, multi-item editing capabilities, local query caching, and progressive web application (PWA) configurations.

#### Added
- **PWA Configuration**: Full web assets added (`web/index.html`, `web/manifest.json`, `web/favicon.png`, and responsive sizing launcher icons) allowing the app to run as a web app.
- **List Duplication**: Users can now copy or duplicate an entire inventory list (items, quantities, and units) directly from the switcher sheet.
- **Multi-Item Selection**: Bulk selection mode allowing users to select multiple items in the list for batch deletion, bulk category relocation, or batch marking.
- **Branding Assets**: Consolidated brand logos under `assets/icon/logo.png`, `assets/icon/adaptive_android_logo.png`, and `assets/icon/adaptive_android_monochrome_logo.png`.
- **Build Scripts**: Added `build_apk.sh` to automate optimized builds, splitting targets per ABI, obfuscating codes, and storing symbols.
- **Cache Layer**: Implemented memory caching (`lib/services/catalog_cache.dart`) to store catalog search configurations and decrease list rendering delays.

#### Changed / Optimized
- **Database Optimizations**: Refactored query execution in [database_helper.dart](file:///home/shreyansh/Documents/projects/flutter/gharkilist/lib/services/database_helper.dart) using prepared statements and batch transactions to reduce disk writes.
- **Provider Performance**: Refactored [app_inventory_provider.dart](file:///home/shreyansh/Documents/projects/flutter/gharkilist/lib/providers/app_inventory_provider.dart) to cache query indexes, preventing unnecessary UI redraws.
- **Git Tracking Cleanup**: Updated [.gitignore](file:///home/shreyansh/Documents/projects/flutter/gharkilist/.gitignore) to exclude generated build files, temporary IDE configurations, and compile-time artifacts.

---

## [0.9.0] - 2026-08-17
### Settings Persistence & Android Dev Security
Focused on persistence settings across app sessions and securing local developer network configurations.

#### Added
- **Android Network Security**: Added `network_security_config.xml` to allow cleartext HTTP traffic during local development (useful for connecting to local database servers or local developer APIs).
- **Settings Persistence**: Integrated `shared_preferences` package inside [app_settings_provider.dart](file:///home/shreyansh/Documents/projects/flutter/gharkilist/lib/providers/app_settings_provider.dart) to save selected language and theme configurations.

#### Changed
- **Edit Sheet Logic**: Improved the bottom popup quantity picker and naming logic in [item_detail_sheet.dart](file:///home/shreyansh/Documents/projects/flutter/gharkilist/lib/views/item_detail_sheet.dart) for a smoother typing experience.
- **Test Suite Updates**: Added widget and provider tests verifying persistent state loads.

---

## [0.8.0] - 2026-08-17
### State Management Refactoring
Migrated the entire UI layer from manual Stateful state-updates to standard provider notifications, separating the presentation layer from inventory database transactions.

#### Added
- **Inventory Provider**: Added [app_inventory_provider.dart](file:///home/shreyansh/Documents/projects/flutter/gharkilist/lib/providers/app_inventory_provider.dart) to handle all list selections, item creations, edits, and deletions.
- **Settings Provider**: Added [app_settings_provider.dart](file:///home/shreyansh/Documents/projects/flutter/gharkilist/lib/providers/app_settings_provider.dart) to manage active theme settings and language selection.

#### Changed
- Refactored [catalog_browse_view.dart](file:///home/shreyansh/Documents/projects/flutter/gharkilist/lib/views/catalog_browse_view.dart), [inventory_home_view.dart](file:///home/shreyansh/Documents/projects/flutter/gharkilist/lib/views/inventory_home_view.dart), and [settings_view.dart](file:///home/shreyansh/Documents/projects/flutter/gharkilist/lib/views/settings_view.dart) to utilize standard `Consumer` widgets and watch providers.

---

## [0.7.0] - 2026-08-17
### Dynamic Bilingual Localization & Unit Tests
Introduced robust bilingual toggles throughout all views, allowing seamless toggling between English and Hindi.

#### Added
- **Bilingual Coverage**: Applied dynamic translations to all list buttons, placeholders, dialogs, error messages, and form fields.
- **Unit Tests**: Created `test/unit_test.dart` to verify key-value translations, locale loading boundaries, and currency parsing logic.

---

## [0.6.0] - 2026-08-16
### WebP Asset Migration & Adaptive Android Icons
Optimized the application's storage footprint and added native Android themed icon support.

#### Added
- **Adaptive Launcher Icons**: Configured XML configurations and added monochrome adaptive icon assets to support Android 13+ Material You themed icons.

#### Changed / Optimized
- **WebP Asset Optimization**: Migrated all pantry placeholder PNG images (e.g. `aata.png`, `ghee.png`, `salt.png`) to compressed `.webp` assets, reducing image sizes by over 89% and shortening cold-boot latency.

---

## [0.5.0] - 2026-08-16
### Advanced Inventory Management UI
Polished the user experience with advanced list filtering, custom item creation, and improved UI feedback.

#### Added
- **Custom Additions**: Added [add_item_form_view.dart](file:///home/shreyansh/Documents/projects/flutter/gharkilist/lib/views/add_item_form_view.dart) to support creating items not present in the default catalog.
- **Custom List Dialog**: Added `create_list_dialog.dart` for adding user-defined lists.
- **Category Filter Sheets**: Added `inventory_filter_sheet.dart` to filter items by category or stock limits.
- **Brand Identity**: Implemented a custom canvas-painted vector logo (`gharkilist_logo.dart`).
- **Interactive UI Components**: Created `inventory_item_tile.dart` and `inventory_tag_bar.dart` to provide rich swipe gestures and tab-based navigation.

---

## [0.4.0] - 2026-08-16
### Assets & Build Ignore Setup
Minor maintenance release to establish file storage structure.

#### Added
- Added standard catalog assets (PNG format) to `assets/images/`.
- Updated `.gitignore` rules for Android build and Gradle cache paths.

---

## [0.3.0] - 2026-08-14
### Localization Service & UI Consolidation
Initial structural improvements.

#### Added
- **Localization Service**: Initial implementation of [localization_service.dart](file:///home/shreyansh/Documents/projects/flutter/gharkilist/lib/services/localization_service.dart) for Hindi-English translation mapping.
- **Standardized Iconography**: Introduced `ItemIconWidget` to render category/item icons consistently across screens.

---

## [0.2.0] - 2026-08-14
### Core Feature Set
Completed the initial functional prototype of Gharkilist.

#### Added
- **SQLite Database Helper**: Implemented [database_helper.dart](file:///home/shreyansh/Documents/projects/flutter/gharkilist/lib/services/database_helper.dart) for offline, privacy-first storage.
- **Bilingual Indian Pantry Catalog**: Added predefined catalog containing over 100 Indian pantry items.
- **WhatsApp Share Service**: Formats grocery lists with item totals and shares formatted texts to WhatsApp.
- **Key Views**: Implemented Browse, Home Dashboard, Add/Edit Bottom Sheets, Photo Capture (dataset labeling helper), and Translator utilities.

---

## [0.1.0] - 2026-08-14
### Skeleton Initialization
- Initial Flutter workspace generation with project metadata and starter configs.
