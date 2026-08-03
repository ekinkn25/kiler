# Mobile — Flutter (Dart)

Flutter 3.x + Material 3. Google ML Kit barkod tarayıcı `mobile_scanner`
paketi üzerinden cihaz üzerinde (offline) çalışır.

## Ekranlar (alt bar)
Kiler · Yemek Tarifleri · Kalori Sayacı · Alışveriş Listesi

## Klasör yapısı (W1-T13'te oluşturulacak)
lib/
  core/        # tema, sabitler, dio yapılandırması, hata yönetimi
  models/      # veri modelleri (freezed / json_serializable)
  services/    # API istemcileri (auth, pantry, recipes, chat)
  providers/   # Riverpod durum yönetimi
  screens/     # ekranlar (pantry, recipes, calories, shopping, chat)
  widgets/     # ortak bileşenler (RecipeCard, IngredientRow, EmptyState)
  router.dart  # go_router rota tanımları

## Ana bağımlılıklar (pubspec.yaml)
flutter_riverpod      # durum yönetimi
dio                   # HTTP istemcisi
go_router             # navigasyon + deep link
flutter_secure_storage # JWT token güvenli saklama
mobile_scanner        # barkod okuma (Google ML Kit)
cached_network_image  # tarif görselleri
percent_indicator     # kalori halkası
flutter_local_notifications # SKT bildirimleri
shimmer               # yükleniyor iskeletleri
freezed / json_serializable # model üretimi

## Çalıştırma
flutter pub get
flutter run --dart-define=API_BASE_URL=http://192.168.1.X:8000/api/v1

## Kurulum kontrolü
flutter doctor