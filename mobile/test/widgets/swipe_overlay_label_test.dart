import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/widgets/swipe/swipe_overlay_label.dart';

void main() {
  Future<void> ciz(WidgetTester tester, {required int x, required int y}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SwipeOverlayLabel(percentX: x, percentY: y)),
      ),
    );
  }

  testWidgets('durgun kartta hicbir etiket yok', (tester) async {
    await ciz(tester, x: 0, y: 0);
    expect(find.text('İSTEMİYORUM'), findsNothing);
    expect(find.text('YAPACAĞIM'), findsNothing);
    expect(find.text('SONRA'), findsNothing);
  });

  testWidgets('cok kucuk kayma etiketi tetiklemez', (tester) async {
    await ciz(tester, x: 3, y: 0);
    expect(find.text('YAPACAĞIM'), findsNothing);
  });

  testWidgets('saga surukleyince YAPACAĞIM cikar', (tester) async {
    await ciz(tester, x: 60, y: 0);
    expect(find.text('YAPACAĞIM'), findsOneWidget);
  });

  testWidgets('sola surukleyince İSTEMİYORUM cikar', (tester) async {
    await ciz(tester, x: -60, y: 0);
    expect(find.text('İSTEMİYORUM'), findsOneWidget);
  });

  testWidgets('yukari surukleyince SONRA cikar', (tester) async {
    await ciz(tester, x: 0, y: -60);
    expect(find.text('SONRA'), findsOneWidget);
  });

  testWidgets('capraz surukleme TEK etiket gosterir', (tester) async {
    await ciz(tester, x: 40, y: -70);
    expect(find.text('SONRA'), findsOneWidget);
    expect(find.text('YAPACAĞIM'), findsNothing);
  });
}