import 'package:flutter_test/flutter_test.dart';
import 'package:shadowtrace/core/app.dart';

void main() {
  testWidgets('App initializes without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ShadowTraceApp());
    expect(find.byType(ShadowTraceApp), findsOneWidget);
  });
}
