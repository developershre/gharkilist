import 'package:flutter_test/flutter_test.dart';
import 'package:gharkilist/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Gharkilist app launch smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GharkilistApp());
    expect(find.byType(GharkilistApp), findsOneWidget);
  });
}

