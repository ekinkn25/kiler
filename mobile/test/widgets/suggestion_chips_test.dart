import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/core/theme/app_theme.dart';
import 'package:kalori/widgets/chat/suggestion_chips.dart';

void main() {
  Future<void> ciz(WidgetTester tester, ValueChanged<String> onSecildi) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: SuggestionChips(onSecildi: onSecildi)),
      ),
    );
  }

  testWidgets('gorev tanimindaki DORT soru da cizilir', (tester) async {
    await ciz(tester, (_) {});

    expect(find.text('Hafif bir şey öner'), findsOneWidget);
    expect(find.text('Kilerimde ne var?'), findsOneWidget);
    expect(find.text('30 dakikada ne yaparım?'), findsOneWidget);
    expect(find.text('Mercimekli bir şey'), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(4));
  });

  testWidgets('cipe dokununca AYNEN cip metni gonderilir', (tester) async {
    String? gonderilen;
    await ciz(tester, (metin) => gonderilen = metin);

    await tester.tap(find.text('Mercimekli bir şey'));
    await tester.pump();

    // Kullaniciya gosterilen metin ile backend'e giden metin AYNI olmali.
    expect(gonderilen, 'Mercimekli bir şey');
  });

  testWidgets('cip satirinda metin kutusu YOK (klavyesiz yol)',
      (tester) async {
    await ciz(tester, (_) {});

    expect(find.byType(TextField), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
  });
}