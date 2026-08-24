import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/core/theme/app_theme.dart';
import 'package:kalori/widgets/calories/portion_selector.dart';

void main() {
  Future<void> ciz(
    WidgetTester tester, {
    required String secili,
    required ValueChanged<String> onSec,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: PortionSelector(secili: secili, onSec: onSec)),
      ),
    );
  }

  testWidgets('uc boy da avuc karsilastirmasiyla cizilir', (tester) async {
    await ciz(tester, secili: 'orta', onSec: (_) {});

    expect(find.text('Küçük'), findsOneWidget);
    expect(find.text('Orta'), findsOneWidget);
    expect(find.text('Büyük'), findsOneWidget);
    expect(find.text('≈ bir avuç'), findsOneWidget);
    // Gram/sayi GORUNMEZ (W3-T17: kullanici gram gormeden secer).
    expect(find.textContaining('gram'), findsNothing);
    expect(find.textContaining('kcal'), findsNothing);
  });

  testWidgets('boya dokununca dogru kod geri cagirilir', (tester) async {
    String? secilen;
    await ciz(tester, secili: 'orta', onSec: (k) => secilen = k);

    await tester.tap(find.text('Büyük'));
    await tester.pump();
    expect(secilen, 'buyuk');

    await tester.tap(find.text('Küçük'));
    await tester.pump();
    expect(secilen, 'kucuk');
  });
}