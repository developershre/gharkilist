import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gharkilist/main.dart';
import 'package:gharkilist/providers/app_inventory_provider.dart';
import 'package:gharkilist/providers/app_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('Gharkilist app launch smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
          ChangeNotifierProvider(create: (_) => AppInventoryProvider()..preloadData()),
        ],
        child: const GharkilistApp(),
      ),
    );
    expect(find.byType(GharkilistApp), findsOneWidget);
  });
}
