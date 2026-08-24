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
    void Function(Availability)? onStatusChange,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PantryItemTile(
            item: kayit,
            onStatusChange: onStatusChange ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('kesin var satirinda kalan gun ve rozet gorunur', (tester) async {
    await ciz(tester, kayitUret());

    expect(find.text('Domates'), findsOneWidget);
    expect(find.text('Kesin var'), findsOneWidget);
    expect(find.text('5 gün sonra soracağız'), findsOneWidget);
  });

  testWidgets('durum rozetine dokununca 3 secenek acilir', (tester) async {
    await ciz(tester, kayitUret());

    await tester.tap(find.byType(PopupMenuButton<Availability>));
    await tester.pumpAndSettle();

    expect(find.text('Var'), findsOneWidget);
    expect(find.text('Emin değilim'), findsOneWidget);
    expect(find.text('Yok (alışverişe ekle)'), findsOneWidget);
  });

  testWidgets('secim dogru hedefi geri cagirir', (tester) async {
    Availability? secilen;
    await ciz(tester, kayitUret(), onStatusChange: (h) => secilen = h);

    await tester.tap(find.byType(PopupMenuButton<Availability>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yok (alışverişe ekle)'));
    await tester.pumpAndSettle();

    expect(secilen, Availability.finished);
  });

  testWidgets('kaynak rozeti kaynaga gore degisir', (tester) async {
    await ciz(tester, kayitUret(source: PantrySource.manuel));
    expect(find.text('Elle'), findsOneWidget);

    await ciz(tester, kayitUret(source: PantrySource.barkod));
    expect(find.text('Barkod'), findsOneWidget);
  });

  testWidgets('emin degiliz satirinda "Hâlâ var mı?" yazar', (tester) async {
    await ciz(tester, kayitUret(availability: Availability.unknown));
    expect(find.text('Emin değiliz'), findsOneWidget);
    expect(find.text('Hâlâ var mı?'), findsOneWidget);
  });
}