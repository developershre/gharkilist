import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'providers/app_inventory_provider.dart';
import 'providers/app_settings_provider.dart';
import 'services/localization_service.dart';
import 'views/catalog_browse_view.dart';
import 'views/inventory_home_view.dart';
import 'views/scan_capture_view.dart';
import 'views/settings_view.dart';
import 'views/translator_view.dart';
import 'widgets/gharkilist_logo.dart';
import 'views/splash_view.dart';
import 'widgets/svg_icon.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(
          create: (_) => AppInventoryProvider()..preloadData(),
        ),
      ],
      child: const GharkilistApp(),
    ),
  );
}

class GharkilistApp extends StatelessWidget {
  const GharkilistApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();

    return ShadApp(
      title: settings.isHindi ? 'घरकीलिस्ट' : 'gharkilist',
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadSlateColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
      ),
      themeMode: settings.themeMode,
      home: const SplashView(),
    );
  }
}

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  void _openScanView(BuildContext context) {
    final settings = context.read<AppSettingsProvider>();
    final inventory = context.read<AppInventoryProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanCaptureView(
          inventoryId: inventory.activeList?.id ?? 1,
          language: settings.language,
          onRefresh: () => inventory.refreshActiveInventory(),
          onItemAdded: (item) => inventory.addInventoryItem(item),
        ),
      ),
    );
  }

  void _openBrowseView(BuildContext context) {
    final settings = context.read<AppSettingsProvider>();
    final inventory = context.read<AppInventoryProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatalogBrowseView(
          language: settings.language,
          onItemAdded: (item) => inventory.addInventoryItem(item),
        ),
      ),
    );
  }

  void _openTranslatorView(BuildContext context) {
    final settings = context.read<AppSettingsProvider>();
    final inventory = context.read<AppInventoryProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TranslatorView(
          language: settings.language,
          onItemAdded: (item) => inventory.addInventoryItem(item),
        ),
      ),
    );
  }

  void _openSettingsView(BuildContext context) {
    final inventory = context.read<AppInventoryProvider>();
    if (inventory.activeList == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsView(
          activeList: inventory.activeList!,
          onOpenTranslator: () => _openTranslatorView(context),
          onListCleared: () => inventory.clearActiveList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final inventory = context.watch<AppInventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (inventory.isInitialLoading || inventory.activeList == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final listsToPass = inventory.allLists.isNotEmpty
        ? inventory.allLists
        : [inventory.activeList!];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: GharkiListLogoWidget(language: settings.language),
        actions: [
          IconButton(
            icon: SvgIcon(
              'settings',
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
              size: 22,
            ),
            tooltip: settings.language == AppLanguage.english
                ? 'Settings'
                : 'सेटिंग्स',
            onPressed: () => _openSettingsView(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: InventoryHomeView(
        activeList: inventory.activeList!,
        allLists: listsToPass,
        items: inventory.inventoryItems,
        language: settings.language,
        onRefresh: () => inventory.refreshActiveInventory(),
        onListChanged: (newList) => inventory.switchActiveList(newList),
        onListCreated: (name) => inventory.createInventoryList(name),
        onAddScanTap: () => _openScanView(context),
        onAddBrowseTap: () => _openBrowseView(context),
      ),
    );
  }
}
