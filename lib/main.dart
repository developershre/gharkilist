import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'models/inventory_item.dart';
import 'models/inventory_list.dart';
import 'services/database_helper.dart';
import 'services/localization_service.dart';
import 'views/catalog_browse_view.dart';
import 'views/empty_state_view.dart';
import 'views/inventory_home_view.dart';
import 'views/inventory_switcher_sheet.dart';
import 'views/scan_capture_view.dart';
import 'views/settings_view.dart';
import 'views/translator_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BhandarKhataApp());
}

class BhandarKhataApp extends StatefulWidget {
  const BhandarKhataApp({super.key});

  static BhandarKhataAppState of(BuildContext context) =>
      context.findAncestorStateOfType<BhandarKhataAppState>()!;

  @override
  State<BhandarKhataApp> createState() => BhandarKhataAppState();
}

class BhandarKhataAppState extends State<BhandarKhataApp> {
  ThemeMode _themeMode = ThemeMode.system; // Default: System Theme
  AppLanguage _language = AppLanguage.english; // Default: English

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void setLanguage(AppLanguage language) {
    setState(() {
      _language = language;
    });
  }

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Bhandar Khata',
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadSlateColorScheme.light(),
        textTheme: ShadTextTheme(
          family: GoogleFonts.inter().fontFamily,
        ),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
        textTheme: ShadTextTheme(
          family: GoogleFonts.inter().fontFamily,
        ),
      ),
      themeMode: _themeMode,
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  InventoryList? _activeList;
  List<InventoryItem> _inventoryItems = [];
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    final lists = await DatabaseHelper.instance.getAllInventories();
    final defaultList = lists.isNotEmpty
        ? lists.firstWhere((l) => l.isDefault, orElse: () => lists.first)
        : InventoryList(id: 1, name: 'Kitchen Pantry', iconEmoji: '🏠', isDefault: true);

    final items = await DatabaseHelper.instance.getInventoryItemsForList(defaultList.id ?? 1);

    if (mounted) {
      setState(() {
        _activeList = defaultList;
        _inventoryItems = items;
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _refreshInventory() async {
    if (_activeList?.id == null) return;
    final items = await DatabaseHelper.instance.getInventoryItemsForList(_activeList!.id!);
    if (mounted) {
      setState(() {
        _inventoryItems = items;
      });
    }
  }

  void _switchActiveList(InventoryList newList) async {
    setState(() {
      _activeList = newList;
    });
    await _refreshInventory();
  }

  void _openScanView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanCaptureView(
          onItemAdded: (item) async {
            final itemWithList = item.copyWith(inventoryId: _activeList?.id ?? 1);
            await DatabaseHelper.instance.addInventoryItem(itemWithList);
            _refreshInventory();
          },
        ),
      ),
    );
  }

  void _openBrowseView() {
    final appState = BhandarKhataApp.of(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatalogBrowseView(
          language: appState.language,
          onItemAdded: (item) async {
            final itemWithList = item.copyWith(inventoryId: _activeList?.id ?? 1);
            await DatabaseHelper.instance.addInventoryItem(itemWithList);
            _refreshInventory();
          },
        ),
      ),
    );
  }

  void _openTranslatorView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TranslatorView(
          onItemAdded: (item) async {
            final itemWithList = item.copyWith(inventoryId: _activeList?.id ?? 1);
            await DatabaseHelper.instance.addInventoryItem(itemWithList);
            _refreshInventory();
          },
        ),
      ),
    );
  }

  void _openSettingsView() {
    if (_activeList == null) return;
    final appState = BhandarKhataApp.of(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsView(
          activeList: _activeList!,
          themeMode: appState.themeMode,
          language: appState.language,
          onSetThemeMode: appState.setThemeMode,
          onSetLanguage: appState.setLanguage,
          onOpenTranslator: _openTranslatorView,
          onListCleared: _refreshInventory,
        ),
      ),
    );
  }

  void _openSwitcherSheet() {
    if (_activeList == null) return;
    final appState = BhandarKhataApp.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InventorySwitcherSheet(
        activeList: _activeList!,
        language: appState.language,
        onListSelected: _switchActiveList,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = BhandarKhataApp.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final language = appState.language;

    if (_isInitialLoading || _activeList == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayListName = LocalizationService.getItemName(
      _activeList!.name,
      _activeList!.name,
      language,
    );

    return Scaffold(
      // SINGLE CLEAN HEADER AT TOP
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        elevation: 0,
        title: InkWell(
          onTap: _openSwitcherSheet,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_activeList!.iconEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    displayListName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // ONLY SETTINGS ICON IN HEADER
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF64748B), size: 26),
            tooltip: language == AppLanguage.english ? 'Settings' : 'सेटिंग्स',
            onPressed: _openSettingsView,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _inventoryItems.isEmpty
          ? EmptyStateView(
              activeList: _activeList!,
              language: language,
              onScanTap: _openScanView,
              onBrowseTap: _openBrowseView,
              onQuickAddCatalogItem: (item) async {
                final inv = InventoryItem(
                  inventoryId: _activeList!.id ?? 1,
                  catalogId: item.id,
                  customName: item.nameEn,
                  nameHi: item.nameHi,
                  category: item.category,
                  quantity: 1.0,
                  unit: item.defaultUnit,
                  catalogItem: item,
                );
                await DatabaseHelper.instance.addInventoryItem(inv);
                _refreshInventory();
              },
            )
          : InventoryHomeView(
              activeList: _activeList!,
              items: _inventoryItems,
              language: language,
              onRefresh: _refreshInventory,
              onListChanged: _switchActiveList,
              onAddScanTap: _openScanView,
              onAddBrowseTap: _openBrowseView,
            ),
    );
  }
}
