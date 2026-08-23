import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/core/theme/app_theme.dart';
import 'package:kalori/models/enums.dart';
import 'package:kalori/models/pantry_item.dart';
import 'package:kalori/widgets/pantry/pantry_item_tile.dart';

void main() {
  PantryItem kayitUret({
    Availability availability = Availability.available,
    PantrySource source = PantrySource.foto,
    int? daysRemaining = 5,
    String displayName = 'Domates',
  }) {
    final simdi = DateTime(2026, 8, 24);
    return PantryItem(
      id: 1,
      ingredient: IngredientSummary(
        id: 29,
        canonicalName: 'domates',
        displayName: displayName,
      ),
      availability: availability,
      source: source,
      daysRemaining: daysRemaining,
      createdAt: simdi,
      updatedAt: simdi,
    );
  }

  Future<void> ciz(
    WidgetTester tester,
    PantryItem kayit, {
    VoidCallback? onStillHave,
    VoidCallback? onFinished,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PantryItemTile(
            item: kayit,
            onStillHave: onStillHave,
            onFinished: onFinished,
          ),
        ),
      ),
    );
  }

  testWidgets('kesin var satirinda kalan gun yazar, hizli buton YOK',
      (tester) async {
    await ciz(tester, kayitUret());

    expect(find.text('Domates'), findsOneWidget);
    expect(find.text('Kesin var'), findsOneWidget);
    expect(find.text('5 gün sonra soracağız'), findsOneWidget);
    // 'Kesin var' bolumunde dogrulama istemiyoruz.
    expect(find.text('Var'), findsNothing);
    expect(find.text('Bitti'), findsNothing);
  });

  testWidgets('emin degiliz satirinda [Var] ve [Bitti] cikar', (tester) async {
    await ciz(
      tester,
      kayitUret(availability: Availability.unknown, daysRemaining: 0),
      onStillHave: () {},
      onFinished: () {},
    );

    expect(find.text('Emin değiliz'), findsOneWidget);
    expect(find.text('Var'), findsOneWidget);
    expect(find.text('Bitti'), findsOneWidget);
    expect(find.text('Hâlâ var mı?'), findsOneWidget);
  });

  testWidgets('butonlar dogru geri cagriyi tetikler', (tester) async {
    var varBasildi = false;
    var bittiBasildi = false;

    await ciz(
      tester,
      kayitUret(availability: Availability.unknown),
      onStillHave: () => varBasildi = true,
      onFinished: () => bittiBasildi = true,
    );

    await tester.tap(find.text('Var'));
    await tester.pump();
    expect(varBasildi, isTrue);
    expect(bittiBasildi, isFalse);

    await tester.tap(find.text('Bitti'));
    await tester.pump();
    expect(bittiBasildi, isTrue);
  });

  testWidgets('kaynak rozeti kaynaga gore degisir', (tester) async {
    await ciz(tester, kayitUret(source: PantrySource.barkod));
    expect(find.text('Barkod'), findsOneWidget);

    await ciz(tester, kayitUret(source: PantrySource.foto));
    expect(find.text('Fotoğraf'), findsOneWidget);
  });

  testWidgets('kalan gun bilinmiyorsa sure metni bos gecer', (tester) async {
    await ciz(tester, kayitUret(daysRemaining: null));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('gün sonra'), findsNothing);
  });

  testWidgets('bugun soracagiz durumu', (tester) async {
    await ciz(tester, kayitUret(daysRemaining: 0));
    expect(find.text('Bugün soracağız'), findsOneWidget);
  });
}