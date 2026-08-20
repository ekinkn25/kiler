import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/core/theme/app_theme.dart';
import 'package:kalori/widgets/empty_illustration.dart';
import 'package:kalori/widgets/empty_state.dart';

void main() {
  Future<void> ciz(
    WidgetTester tester,
    Widget child, {
    ThemeData? tema,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: tema ?? AppTheme.light,
        home: Scaffold(body: child),
      ),
    );
  }

  group('EmptyIllustration', () {
    testWidgets('verilen olcude KARE alan kaplar', (tester) async {
      await ciz(tester, const EmptyIllustration(icon: Icons.restaurant_menu));

      expect(
        tester.getSize(find.byType(EmptyIllustration)),
        const Size(180, 180),
      );
    });

    testWidgets('olcu degisince orantili kucultur', (tester) async {
      await ciz(
        tester,
        const EmptyIllustration(icon: Icons.kitchen, size: 120),
      );

      expect(
        tester.getSize(find.byType(EmptyIllustration)),
        const Size(120, 120),
      );
    });

    testWidgets('koyu temada da hatasiz cizilir', (tester) async {
      await ciz(
        tester,
        const EmptyIllustration(icon: Icons.kitchen),
        tema: AppTheme.dark,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(EmptyIllustration), findsOneWidget);
    });
  });

  group('EmptyState', () {
    testWidgets('varsayilan halde SADE ikon cizer (geriye uyum)',
        (tester) async {
      await ciz(
        tester,
        const EmptyState(icon: Icons.kitchen, title: 'Kilerin boş'),
      );

      expect(find.byType(EmptyIllustration), findsNothing);
      expect(tester.widget<Icon>(find.byIcon(Icons.kitchen)).size, 64);
    });

    testWidgets('illustrated: true ile BUYUK GORSEL cizer', (tester) async {
      await ciz(
        tester,
        const EmptyState(
          icon: Icons.restaurant_menu,
          illustrated: true,
          title: 'Bugünlük bu kadar!',
        ),
      );

      expect(find.byType(EmptyIllustration), findsOneWidget);
    });

    testWidgets('baslik ve mesaj gorunur', (tester) async {
      await ciz(
        tester,
        const EmptyState(
          icon: Icons.restaurant_menu,
          illustrated: true,
          title: 'Bugünlük bu kadar!',
          message: 'Kilerine bir şeyler ekle ya da yarın tekrar bak.',
        ),
      );

      expect(find.text('Bugünlük bu kadar!'), findsOneWidget);
      expect(
        find.text('Kilerine bir şeyler ekle ya da yarın tekrar bak.'),
        findsOneWidget,
      );
    });

    testWidgets('aksiyon butonu yalnizca etiket VE geri cagri varsa cikar',
        (tester) async {
      await ciz(
        tester,
        const EmptyState(
          icon: Icons.restaurant_menu,
          illustrated: true,
          title: 'Bugünlük bu kadar!',
          actionLabel: 'Baştan bak', // onAction YOK
        ),
      );

      expect(find.text('Baştan bak'), findsNothing);
    });
  });
}