import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharkilist/models/inventory_item.dart';
import 'package:gharkilist/models/inventory_list.dart';
import 'package:gharkilist/services/localization_service.dart';
import 'package:gharkilist/views/inventory_home_view.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:gharkilist/providers/app_inventory_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('InventoryHomeView Reorder Test under Filtering', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    // Create some items
    final itemA = InventoryItem(
      id: 1,
      inventoryId: 1,
      catalogId: 'item_a',
      customName: 'Item A',
      category: 'Spices',
      quantity: 1.0,
      unit: 'pcs',
      displayOrder: 0,
    );
    final itemB = InventoryItem(
      id: 2,
      inventoryId: 1,
      catalogId: 'item_b',
      customName: 'Item B',
      category: 'Grains',
      quantity: 2.0,
      unit: 'pcs',
      displayOrder: 1,
    );
    final itemC = InventoryItem(
      id: 3,
      inventoryId: 1,
      catalogId: 'item_c',
      customName: 'Item C',
      category: 'Spices',
      quantity: 3.0,
      unit: 'pcs',
      displayOrder: 2,
    );

    final activeList = InventoryList(id: 1, name: 'Main List');

    // List of items
    final List<InventoryItem> itemsList = [itemA, itemB, itemC];

    bool refreshCalled = false;

    // Pump widget
    await tester.pumpWidget(
      ChangeNotifierProvider<AppInventoryProvider>(
        create: (_) => AppInventoryProvider(),
        child: ShadApp(
          home: Scaffold(
            body: InventoryHomeView(
              activeList: activeList,
              allLists: [activeList],
              items: itemsList,
              language: AppLanguage.english,
              onRefresh: () {
                refreshCalled = true;
              },
              onListChanged: (list) {},
              onListCreated: (name) {},
              onAddScanTap: () {},
              onAddBrowseTap: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify it renders ReorderableListView
    expect(find.byType(ReorderableListView), findsOneWidget);

    // Get the state of InventoryHomeView
    final stateFinder = find.byType(InventoryHomeView);
    final dynamic state = tester.state(stateFinder);

    // Verify initial local items
    expect(state.localItemsForTest.length, equals(3));
    expect(state.localItemsForTest[0].customName, equals('Item A'));
    expect(state.localItemsForTest[1].customName, equals('Item B'));
    expect(state.localItemsForTest[2].customName, equals('Item C'));

    // Apply category filter "Spices"
    state.setCategoryFilterForTest('Spices');
    await tester.pump();

    // Verify filtered items
    expect(state.filteredItemsForTest.length, equals(2));
    expect(state.filteredItemsForTest[0].customName, equals('Item A'));
    expect(state.filteredItemsForTest[1].customName, equals('Item C'));

    // Now reorder index 0 (Item A) to index 2 (after Item C)
    // The method is: _onReorderItems(int oldIndex, int newIndex)
    // We call it dynamically using the state object
    await tester.runAsync(() async {
      await state.onReorderItemsForTest(0, 2);
    });
    await tester.pump();

    // Verify the reordered _localItems
    // Order in local items should be Item B (index 0), Item C (index 1), Item A (index 2)
    expect(state.localItemsForTest.length, equals(3));
    expect(state.localItemsForTest[0].customName, equals('Item B'));
    expect(state.localItemsForTest[1].customName, equals('Item C'));
    expect(state.localItemsForTest[2].customName, equals('Item A'));

    // Verify refresh was called
    expect(refreshCalled, isTrue);
  });
}
