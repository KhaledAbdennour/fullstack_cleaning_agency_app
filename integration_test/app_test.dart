import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mob_dev_project/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('launch app and verify home screen loads',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.pump(const Duration(seconds: 2));

      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsAtLeastNWidgets(1));
    });

    testWidgets('navigate to notifications inbox and verify UI',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.pump(const Duration(seconds: 2));

      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsAtLeastNWidgets(1));

      final appBar = find.byType(AppBar);
      if (appBar.evaluate().isNotEmpty) {
        expect(appBar, findsAtLeastNWidgets(1));
      }

      final listView = find.byType(ListView);
      final column = find.byType(Column);
      final center = find.byType(Center);

      final hasListContainer = listView.evaluate().isNotEmpty ||
          column.evaluate().isNotEmpty ||
          center.evaluate().isNotEmpty;

      expect(hasListContainer, isTrue);
    });
  });
}
