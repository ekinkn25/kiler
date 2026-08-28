import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/kilo_kaydi.dart';
import 'package:kalori/widgets/kilo_grafigi.dart';

/// Grafigin cizim testleri.
///
/// CustomPainter'in urettigi pikselleri dogrulamiyoruz - deger olcek
/// hesabinin SINIR durumlarda patlamadigini dogruluyoruz. Sifira bolme
/// veya bos listede reduce() cagirmak burada gorunur.
void main() {
  Widget sar(List<KiloKaydi> kayitlar) => MaterialApp(
    home: Scaffold(body: KiloGrafigi(kayitlar: kayitlar)),
  );

  KiloKaydi kayit(int gunOnce, double kilo) => KiloKaydi(
    id: gunOnce,
    gun: DateTime(2026, 8, 28).subtract(Duration(days: gunOnce)),
    kiloKg: kilo,
  );

  testWidgets('bos liste cizilirken patlamaz', (tester) async {
    await tester.pumpWidget(sar(const []));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tek kayit: sifira bolme yok', (tester) async {
    // Tek nokta -> hem tarih araligi hem kilo araligi SIFIR. Olcek
    // hesabi korunmasaydi burada NaN uretilirdi.
    await tester.pumpWidget(sar([kayit(0, 80)]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hic degismemis kilo: duz cizgi cizilir', (tester) async {
    await tester.pumpWidget(sar([kayit(10, 80), kayit(5, 80), kayit(0, 80)]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('coklu kayit cizilir', (tester) async {
    await tester.pumpWidget(sar([
      kayit(30, 84.2),
      kayit(20, 83),
      kayit(10, 81.5),
      kayit(0, 80.1),
    ]));

    expect(find.byType(KiloGrafigi), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cok sayida kayitta da cizim tamamlanir', (tester) async {
    // 20'den fazla noktada nokta isaretleri seyreltiliyor; o dal da
    // en az bir kez calissin.
    await tester.pumpWidget(sar([
      for (var i = 60; i >= 0; i--) kayit(i, 80 + (i % 7) * 0.4),
    ]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sifir yukseklikte alanda cizim iptal edilir', (tester) async {
    // Yerlesim daralinca (orn. bir animasyon sirasinda) negatif cizim
    // alani olusabiliyor; boyaci bunu sessizce atlamali.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 10,
          child: KiloGrafigi(kayitlar: [kayit(5, 80), kayit(0, 79)]),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
