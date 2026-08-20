import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/core/theme/app_theme.dart';
import 'package:kalori/models/recipe_card.dart';
import 'package:kalori/widgets/swipe/recipe_swipe_card.dart';

/// DIKKAT: hicbir testte imageUrl DOLU verilmiyor.
///
/// CachedNetworkImage, dosya onbellegi icin path_provider eklentisini
/// kullanir; widget testinde eklenti katmani olmadigi icin
/// MissingPluginException firlatir ve testler kirilgan olur. Gorsel
/// yukleme davranisi (placeholder / errorWidget) cihazda elle
/// dogrulanir; burada KART ICERIGI test edilir.
void main() {
  RecipeCard kartUret({
    String title = 'Mercimek Çorbası',
    double pantry = 0.85,
    int? prepTime = 10,
    int? cookTime = 20,
    String? difficulty = 'kolay',
    List<String> dietTags = const [],
    double calories = 410,
  }) {
    return RecipeCard(
      id: 'test-1',
      title: title,
      slug: 'test-1',
      caloriesPerServing: calories,
      servings: 2,
      prepTime: prepTime,
      cookTime: cookTime,
      difficulty: difficulty,
      dietTags: dietTags,
      finalScore: 0.6,
      scoreBreakdown: ScoreBreakdown(
        pantry: pantry,
        calorie: 0.9,
        taste: 0.5,
        time: 1,
        weights: const ScoreWeights(
          pantry: 0.5,
          calorie: 0.2,
          taste: 0.2,
          time: 0.1,
        ),
      ),
    );
  }

  // Kart Positioned/StackFit.expand kullanir; SINIRLI bir kutu sart.
  Future<void> ciz(WidgetTester tester, RecipeCard kart) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 560,
              child: RecipeSwipeCard(card: kart),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('baslik ve uc rozet birlikte cizilir', (tester) async {
    await ciz(tester, kartUret());

    expect(find.text('Mercimek Çorbası'), findsOneWidget);
    expect(find.text('410 kcal'), findsOneWidget);
    expect(find.text('30 dk'), findsOneWidget); // prep 10 + cook 20
    expect(find.text('Kolay'), findsOneWidget);
  });

  testWidgets('kiler uyum etiketi yuzdeye yuvarlanir', (tester) async {
    // W3-T06 gorev metnindeki ornegin birebir karsiligi.
    await ciz(tester, kartUret(pantry: 0.8532));
    expect(find.text('Kilerinle %85 uyumlu'), findsOneWidget);
  });

  testWidgets('kiler bos oldugunda %0 gosterilir', (tester) async {
    await ciz(tester, kartUret(pantry: 0));
    expect(find.text('Kilerinle %0 uyumlu'), findsOneWidget);
  });

  testWidgets('kalori ondalikli gelirse tam sayiya yuvarlanir', (tester) async {
    await ciz(tester, kartUret(calories: 410.6));
    expect(find.text('411 kcal'), findsOneWidget);
  });

  testWidgets('diyet cipleri listelenir', (tester) async {
    await ciz(tester, kartUret(dietTags: const ['vejetaryen', 'glutensiz']));

    expect(find.text('vejetaryen'), findsOneWidget);
    expect(find.text('glutensiz'), findsOneWidget);
  });

  testWidgets('diyet etiketi yoksa cip cizilmez', (tester) async {
    await ciz(tester, kartUret());
    expect(find.text('vejetaryen'), findsNothing);
  });

  testWidgets('zorluk null ise o rozet hic cizilmez', (tester) async {
    await ciz(tester, kartUret(difficulty: null));

    expect(find.text('Kolay'), findsNothing);
    expect(find.text('Orta'), findsNothing);
    expect(find.text('Zor'), findsNothing);
    // Diger rozetler etkilenmemeli.
    expect(find.text('410 kcal'), findsOneWidget);
  });

  testWidgets('sure bilgisi yoksa sure rozeti cizilmez', (tester) async {
    await ciz(tester, kartUret(prepTime: null, cookTime: null));

    expect(find.text('0 dk'), findsNothing);
    expect(find.textContaining(' dk'), findsNothing);
  });

  testWidgets('sadece pisirme suresi varsa toplam dogru hesaplanir',
      (tester) async {
    await ciz(tester, kartUret(prepTime: null, cookTime: 25));
    expect(find.text('25 dk'), findsOneWidget);
  });

  testWidgets('bilinmeyen zorluk kodu oldugu gibi gosterilir', (tester) async {
    await ciz(tester, kartUret(difficulty: 'cok_zor'));
    expect(find.text('cok_zor'), findsOneWidget);
  });

  testWidgets('uzun baslik iki satirda kirpilir', (tester) async {
    const uzun = 'Fırında Sebzeli Tavuk Sote ve Yanında Bulgur Pilavı '
        'ile Cacık Tarifi Uzun Başlık Denemesi';
    await ciz(tester, kartUret(title: uzun));

    final Text baslik = tester.widget<Text>(find.text(uzun));
    expect(baslik.maxLines, 2);
    expect(baslik.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull); // tasma hatasi yok
  });

  testWidgets('gorsel yokken kart cokmez', (tester) async {
    await ciz(tester, kartUret());
    expect(tester.takeException(), isNull);
    expect(find.byType(RecipeSwipeCard), findsOneWidget);
  });
}