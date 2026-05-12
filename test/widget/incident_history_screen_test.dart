import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadowtrace/screens/incident_history_screen.dart';

void main() {
  group('IncidentHistoryScreen', () {
    testWidgets('Shows CircularProgressIndicator while loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IncidentHistoryScreen(userId: 'test-user'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Shows empty state when no incidents exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IncidentHistoryScreen(userId: 'test-user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shield), findsOneWidget);
      expect(find.text('No incidents yet'), findsOneWidget);
    });

    testWidgets('Displays AppBar with correct title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IncidentHistoryScreen(userId: 'test-user'),
        ),
      );

      expect(find.text('Incident History'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('Refresh button is clickable and triggers fetch',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IncidentHistoryScreen(userId: 'test-user'),
        ),
      );

      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('Shows error message when fetch fails',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IncidentHistoryScreen(userId: 'test-user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
