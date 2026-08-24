import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/core/theme/app_theme.dart';
import 'package:kalori/models/daily_summary.dart';
import 'package:kalori/widgets/calories/calorie_ring.dart';
import 'package:kalori/widgets/calories/macro_bars.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

void main() {
  Future<void> ciz(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  CircularPercentIndicator halka(WidgetTester tester) =>
      tester.widget<CircularPercentIndicator>(
        find.byType(CircularPercentIndicator),
      );

  group('CalorieRing', () {
    testWidgets('alinan kalori ve kalan miktar gosterilir', (tester) async {
      await ciz(tester, const CalorieRing(consumed: 1200, target: 2000));
      await tester.pumpAndSettle();

      expect(find.text('1200'), findsOneWidget);
      expect(find.textContaining('800 kcal kaldı'), findsOneWidget);
    });

    testWidgets('hedef asilinca KIRMIZI alarm YOK', (tester) async {
      // W3-T14 SUCLAMA YASAGI: asim error rengiyle gosterilemez.
      await ciz(tester, const CalorieRing(consumed: 2500, target: 2000));
      await tester.pumpAndSettle();

      expect(halka(tester).progressColor,
          isNot(AppTheme.light.colorScheme.error));
      expect(find.textContaining('500 kcal fazla'), findsOneWidget);
    });

    testWidgets('oran 1 uzerine cikamaz', (tester) async {
      await ciz(tester, const CalorieRing(consumed: 4000, target: 2000));
      await tester.pumpAndSettle();

      // percent 0..1 disinda olursa paket assert atar.
      expect(halka(tester).percent, 1.0);
    });

    testWidgets('hedef sifirken sifira bolme hatasi vermez', (tester) async {
      await ciz(tester, const CalorieRing(consumed: 500, target: 0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('MacroBars', () {
    testWidgets('uc besin de basligi ve orani ile cizilir', (tester) async {
      await ciz(
        tester,
        const MacroBars(
          consumed: MacroBreakdown(proteinG: 45, carbG: 120, fatG: 30, fiberG: 12),
          target: MacroBreakdown(proteinG: 90, carbG: 240, fatG: 60, fiberG: 28),
        ),
      );

      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Karb.'), findsOneWidget);
      expect(find.text('Lif'), findsOneWidget);
      expect(find.text('Yağ'), findsOneWidget);
      expect(find.text('45 / 90 g'), findsOneWidget);
      // JARGON YASAGI: 'makro' kelimesi ekranda GECMEMELI.
      expect(find.textContaining('akro'), findsNothing);
    });

    testWidgets('hedef sifirken cokmez', (tester) async {
      await ciz(
        tester,
        const MacroBars(
          consumed: MacroBreakdown(proteinG: 10),
          target: MacroBreakdown(),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}