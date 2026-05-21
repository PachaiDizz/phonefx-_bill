import 'package:flutter_test/flutter_test.dart';
import 'package:phonefx_plus/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const PhoneFXApp());
    expect(find.text('PhoneFX+'), findsOneWidget);
  });
}