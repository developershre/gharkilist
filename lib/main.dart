import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'models/inventory_item.dart';
import 'models/inventory_list.dart';
import 'services/database_helper.dart';
import 'services/localization_service.dart';
import 'views/catalog_browse_view.dart';
import 'views/inventory_home_view.dart';
import 'views/scan_capture_view.dart';
import 'views/settings_view.dart';
import 'views/translator_view.dart';
import 'widgets/gharkilist_logo.dart';

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
        textTheme: ShadTextTheme(family: GoogleFonts.inter().fontFamily),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
        textTheme: ShadTextTheme(family: GoogleFonts.inter().fontFamily),
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
  List<InventoryList> _allLists = [];
  List<InventoryItem> _inventoryItems = [];
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _loadAllLists() async {
    final lists = await DatabaseHelper.instance.getAllInventories();
    if (mounted) {
      setState(() {
        _allLists = lists;
      });
    }
  }

  Future<void> _initialLoad() async {
    final lists = await DatabaseHelper.instance.getAllInventories();
    final defaultList = lists.isNotEmpty
        ? lists.firstWhere(
            (l) => l.name.toLowerCase().contains('mahine') || l.isDefault,
            orElse: () => lists.first,
          )
        : InventoryList(
            id: 1,
            name: 'Mahine ka',
            iconEmoji: '🏠',
            isDefault: true,
          );

    final items = await DatabaseHelper.instance.getInventoryItemsForList(
      defaultList.id ?? 1,
    );

    if (mounted) {
      setState(() {
        _allLists = lists;
        _activeList = defaultList;
        _inventoryItems = items;
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _refreshInventory() async {
    if (_activeList?.id == null) return;
    final items = await DatabaseHelper.instance.getInventoryItemsForList(
      _activeList!.id!,
    );
    if (mounted) {
      setState(() {
        _inventoryItems = items;
      });
    }
  }

  void _switchActiveList(InventoryList newList) async {
    final listId = newList.id;
    final items = listId != null
        ? await DatabaseHelper.instance.getInventoryItemsForList(listId)
        : <InventoryItem>[];
    if (mounted) {
      setState(() {
        _activeList = newList;
        _inventoryItems = items;
      });
    }
  }

  void _onListCreated(InventoryList newList) async {
    await _loadAllLists();
    _switchActiveList(newList);
  }

  void _openScanView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanCaptureView(
          inventoryId: _activeList?.id ?? 1,
          onRefresh: _refreshInventory,
          onItemAdded: (item) async {
            final itemWithList = item.copyWith(
              inventoryId: _activeList?.id ?? 1,
            );
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
            final itemWithList = item.copyWith(
              inventoryId: _activeList?.id ?? 1,
            );
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
            final itemWithList = item.copyWith(
              inventoryId: _activeList?.id ?? 1,
            );
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
          onListCleared: () async {
            await _refreshInventory();
            await _loadAllLists();
          },
        ),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final listsToPass = _allLists.isNotEmpty ? _allLists : [_activeList!];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const GharkiListLogoWidget(),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
              size: 26,
            ),
            tooltip: language == AppLanguage.english ? 'Settings' : 'सेटिंग्स',
            onPressed: _openSettingsView,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: InventoryHomeView(
        activeList: _activeList!,
        allLists: listsToPass,
        items: _inventoryItems,
        language: language,
        onRefresh: _refreshInventory,
        onListChanged: _switchActiveList,
        onListCreated: _onListCreated,
        onAddScanTap: _openScanView,
        onAddBrowseTap: _openBrowseView,
      ),
    );
  }
}
