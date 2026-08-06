// uygulamadaki tüm rota yolları ve adları
//ekranda /tarigler gibi ham dizge yok hep bu sınıf kullanılmıyor
//bu sayede bir yol değiştiğinde derleyici tüm çağrı noktalarını görebilir

class AppRouters {
  const AppRouters._();

  //kabuk içi sekmeler
  static const String pantry = '/kiler';
  static const String recipes = '/tarifler';
  static const String calories = '/kalori';
  static const String shopping = '/liste';

  // Sekme içi alt rotalar 
  /// Tam yol: /tarifler/:id
  static const String recipeDetailSegment = ':id';
  static String recipeDetail(String id) => '$recipes/$id';

  // Kabuk dışı (tam ekran) 
  static const String chat = '/sohbet';
  static const String scanner = '/tara';
  static const String profile = '/profil';
  static const String onboarding = '/onboarding';
  static const String login = '/giris';
  static const String register = '/kayit';

  /// GECICI: W1-T13'ten kalan kurulum dogrulama ekrani.
  static const String dev = '/dev';

  // Rota adlari (isimle gezinme icin) 
  static const String nameRecipeDetail = 'tarif-detay';
  static const String nameChat = 'sohbet';
}