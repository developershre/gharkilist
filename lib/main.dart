import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'models/inventory_item.dart';
import 'models/inventory_list.dart';
import 'services/database_helper.dart';
import 'views/catalog_browse_view.dart';
import 'views/empty_state_view.dart';
import 'views/inventory_home_view.dart';
import 'views/inventory_switcher_sheet.dart';
import 'views/scan_capture_view.dart';
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
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  ThemeMode get themeMode => _themeMode;

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
        : InventoryList(id: 1, name: 'रसोई का सामान (Kitchen)', iconEmoji: '🏠', isDefault: true);

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatalogBrowseView(
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

  void _openSwitcherSheet() {
    if (_activeList == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InventorySwitcherSheet(
        activeList: _activeList!,
        onListSelected: _switchActiveList,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = BhandarKhataApp.of(context);
    final isDark = appState.themeMode == ThemeMode.dark;

    if (_isInitialLoading || _activeList == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
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
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    _activeList!.name,
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
          IconButton(
            icon: const Icon(Icons.g_translate, color: Color(0xFF38BDF8), size: 24),
            tooltip: 'हिंदी / English अनुवाद् (Translator)',
            onPressed: _openTranslatorView,
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? const Color(0xFFFACC15) : const Color(0xFF334155),
              size: 24,
            ),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: appState.toggleTheme,
          ),
        ],
      ),
      body: _inventoryItems.isEmpty
          ? EmptyStateView(
              activeList: _activeList!,
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
              onRefresh: _refreshInventory,
              onListChanged: _switchActiveList,
              onAddScanTap: _openScanView,
              onAddBrowseTap: _openBrowseView,
            ),
    );
  }
}
