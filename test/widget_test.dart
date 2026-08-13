import 'package:flutter_test/flutter_test.dart';
import 'package:gharkilist/main.dart';

void main() {
  testWidgets('Bhandar Khata app launch smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BhandarKhataApp());
    expect(find.byType(BhandarKhataApp), findsOneWidget);
  });
}
