import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_app/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HooksApp());
    expect(find.text('Welcome to Hooks'), findsOneWidget);
  });
}
