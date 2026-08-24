import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/core/theme/app_theme.dart';
import 'package:kalori/models/detected_ingredient.dart';
import 'package:kalori/widgets/chat/detected_ingredients_sheet.dart';

void main() {
  const yuksek = DetectedIngredient(
    rawName: 'domates',
    canonicalName: 'domates',
    displayName: 'Domates',
    confidence: 0.92,
  );
  const dusuk = DetectedIngredient(
    rawName: 'kabak?',
    canonicalName: 'kabak',
    displayName: 'Kabak',
    confidence: 0.35,
  );
  const sozluksuz = DetectedIngredient(
    rawName: 'yesil sey',
    canonicalName: null,
    displayName: 'Yeşil şey',
    confidence: 0.80,
  );

  /// Alt sayfayi acar ve dondugu degeri yakalar.
  Future<List<String>?> ac(
    WidgetTester tester,
    List<DetectedIngredient> tespitler,
  ) async {
    List<String>? sonuc;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                sonuc = await showDetectedIngredientsSheet(
                  context,
                  tespitler: tespitler,
                );
              },
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    return sonuc;
  }

  testWidgets('yuksek guvenli ISARETLI, dusuk guvenli ISARETSIZ gelir',
      (tester) async {
    await ac(tester, const [yuksek, dusuk]);

    final kutular =
        tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(kutular.length, 2);
    // Sira tespit sirasiyla ayni.
    expect(kutular.first.value, isTrue);
    expect(kutular.last.value, isFalse);

    // Buton yalnizca isaretli olani sayar.
    expect(find.textContaining('1 malzemeyi'), findsOneWidget);
  });

  testWidgets('sozlukte olmayan tespit SECILEMEZ', (tester) async {
    await ac(tester, const [sozluksuz]);

    final kutu =
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    // onChanged null -> pasif.
    expect(kutu.onChanged, isNull);
    expect(find.text('Sözlüğümde yok, ekleyemiyorum'), findsOneWidget);
  });

  testWidgets('isaret kaldirilinca secim sayisi duser', (tester) async {
    await ac(tester, const [yuksek]);
    expect(find.textContaining('1 malzemeyi'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    expect(find.text('Malzeme seç'), findsOneWidget);
  });

  testWidgets('onaylayinca SECILI canonical_name listesi doner',
      (tester) async {
    // Not: sonuc degiskeni pop sonrasi doluyor, pumpAndSettle ile bekle.
    List<String>? sonuc;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                sonuc = await showDetectedIngredientsSheet(
                  context,
                  tespitler: const [yuksek, dusuk],
                );
              },
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('1 malzemeyi'));
    await tester.pumpAndSettle();

    expect(sonuc, ['domates']);
  });

  testWidgets('Simdi degil ile null doner', (tester) async {
    List<String>? sonuc;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                sonuc = await showDetectedIngredientsSheet(
                  context,
                  tespitler: const [yuksek],
                );
              },
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Şimdi değil'));
    await tester.pumpAndSettle();

    expect(sonuc, isNull);
  });
}