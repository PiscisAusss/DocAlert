import 'package:docalert/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('afișează documentele demo și permite căutarea', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DocApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Documente familie'), findsOneWidget);
    expect(find.text('Buletin de identitate'), findsOneWidget);
    expect(find.text('Permis de conducere'), findsOneWidget);

    await tester.tap(find.byTooltip('Caută'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'RCA');
    await tester.pump();

    expect(find.text('Asigurare RCA'), findsOneWidget);
    expect(find.text('Buletin de identitate'), findsNothing);
  });
}
