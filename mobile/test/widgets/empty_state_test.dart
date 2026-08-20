import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/core/theme/app_theme.dart';
import 'package:kalori/widgets/empty_illustration.dart';
import 'package:kalori/widgets/empty_state.dart';
import 'package:kalori/widgets/app_button.dart';

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

        testWidgets('iki aksiyon birlikte cizilir', (tester) async {
      await ciz(
        tester,
        EmptyState(
          icon: Icons.restaurant_menu,
          illustrated: true,
          title: 'Bugünlük bu kadar!',
          actionLabel: 'Fotoğraf çek',
          actionIcon: Icons.photo_camera_outlined,
          onAction: () {},
          secondaryActionLabel: 'Barkod okut',
          secondaryActionIcon: Icons.qr_code_scanner,
          onSecondaryAction: () {},
        ),
      );

      expect(find.byType(AppButton), findsNWidgets(2));
      expect(find.text('Fotoğraf çek'), findsOneWidget);
      expect(find.text('Barkod okut'), findsOneWidget);
    });

    testWidgets('birincil DOLU, ikincil CERCEVELI cizilir', (tester) async {
      await ciz(
        tester,
        EmptyState(
          icon: Icons.restaurant_menu,
          title: 'Bugünlük bu kadar!',
          actionLabel: 'Fotoğraf çek',
          onAction: () {},
          secondaryActionLabel: 'Barkod okut',
          onSecondaryAction: () {},
        ),
      );

      final AppButton birincil = tester.widget<AppButton>(
        find.ancestor(
          of: find.text('Fotoğraf çek'),
          matching: find.byType(AppButton),
        ),
      );
      final AppButton ikincil = tester.widget<AppButton>(
        find.ancestor(
          of: find.text('Barkod okut'),
          matching: find.byType(AppButton),
        ),
      );

      expect(birincil.variant, AppButtonVariant.primary);
      expect(ikincil.variant, AppButtonVariant.secondary);
    });

    testWidgets('her buton KENDI geri cagrisini tetikler', (tester) async {
      var foto = false;
      var barkod = false;

      await ciz(
        tester,
        EmptyState(
          icon: Icons.restaurant_menu,
          title: 'Bugünlük bu kadar!',
          actionLabel: 'Fotoğraf çek',
          onAction: () => foto = true,
          secondaryActionLabel: 'Barkod okut',
          onSecondaryAction: () => barkod = true,
        ),
      );

      await tester.tap(find.text('Fotoğraf çek'));
      await tester.pump();
      expect(foto, isTrue);
      expect(barkod, isFalse);

      await tester.tap(find.text('Barkod okut'));
      await tester.pump();
      expect(barkod, isTrue);
    });

    testWidgets('ikincil aksiyon yalnizca etiket VE geri cagri varsa cikar',
        (tester) async {
      await ciz(
        tester,
        EmptyState(
          icon: Icons.restaurant_menu,
          title: 'Bugünlük bu kadar!',
          actionLabel: 'Fotoğraf çek',
          onAction: () {},
          secondaryActionLabel: 'Barkod okut', // onSecondaryAction YOK
        ),
      );

      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text('Barkod okut'), findsNothing);
    });

    testWidgets('kucuk ekranda tasma hatasi vermez', (tester) async {
      tester.view.physicalSize = const Size(360, 560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await ciz(
        tester,
        EmptyState(
          icon: Icons.restaurant_menu,
          illustrated: true,
          title: 'Bugünlük bu kadar!',
          message: 'Kilerine bir şeyler ekle ya da yarın tekrar bak.',
          actionLabel: 'Fotoğraf çek',
          onAction: () {},
          secondaryActionLabel: 'Barkod okut',
          onSecondaryAction: () {},
        ),
      );

      expect(tester.takeException(), isNull);
    });
    
  });
}