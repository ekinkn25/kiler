# Hata Ayıklama ve Dayanıklılık (W4-T15)

**Tarih:** 2026-08-27 &nbsp;|&nbsp; **Dal:** `feature/w4-t15-kalite-hata-ayıklama-dayanıklılık`

**Kabul kriteri 1 — kritik/major açık hata yok:** GEÇTİ (10/10 kapatıldı)

**Kabul kriteri 2 — API'ler kapalıyken uygulama kullanılabilir kalıyor:** GEÇTİ (otomatik testlerle; canlı prova aşağıda)

| Test paketi | Sonuç |
|---|---|
| `backend/tests` (tamamı) | **346 geçti**, 0 hata |
| `backend/tests/test_resilience.py` (bu görev) | **26 geçti** |
| `mobile/test` (tamamı) | **87 geçti**, 0 hata |
| `mobile/test/dayaniklilik_test.dart` (bu görev) | **13 geçti** |
| `flutter analyze` | **0 sorun** |

---

## 1. Yaklaşım

Görev dört parçadan oluşuyor: (a) tüm async çağrılarda try/catch, (b) Flutter'da çökme
bariyerleri, (c) backend'de global istisna yakalayıcı, (d) görme modeli veya LLM
çöktüğünde kural tabanlı düşüş.

Düşüşü **test edilebilir** kılmak için önce kasten hata veren sağlayıcılar eklendi
(`VISION_PROVIDER=broken`, `CHAT_PROVIDER=broken`). Ağ kesmek deterministik değil;
bu deterministik ve CI'da da çalışıyor.

İkinci temel karar: **hızlı başarısızlık**. Sağlayıcı tamamen kapalıyken her istek
`MAX_RETRIES` × üstel bekleme × `TIMEOUT_SECONDS` kadar bekliyordu (görme için
2 deneme × 20 sn ≈ 60 sn). 200 yanıt dönse bile 60 saniye bekleyen bir ekran
"kullanılabilir" değildir. Devre kesici, 3 ardışık hatadan sonra sağlayıcıya hiç
gitmeden doğrudan düşüşe geçiyor.

---

## 2. Düşüş (graceful degradation) matrisi

### Hangi hata düşer, hangisi düşmez

| Hata sınıfı | Örnek | Davranış |
|---|---|---|
| `ExternalServiceError` ailesi (`VisionError`, `ChatError`: timeout, rate-limit, 5xx, geçersiz yanıt) | Groq kapalı | **Düşüş.** 200 + `degraded=true` |
| Devre açık | 3 ardışık hata sonrası | **Düşüş**, çağrı hiç yapılmaz |
| `AppError` — kullanıcı hatası (`ImageTooLarge` 413, `UnsupportedImageType` 415, `EmptyImage` 400, `InvalidImage` 400) | 20 MB PNG | **Düşüş yok.** Kullanıcı düzeltebilir; sessizce yutmak yanlış |
| Bizim kotamız (`VisionDailyLimitExceeded`, `ChatDailyLimitExceeded` 429) | günlük 30 foto doldu | **Düşüş yok.** Kasıtlı sınır |
| `UnauthorizedError` / `PermissionDeniedError` | token süresi doldu | **Düşüş yok** |
| Mongo (`PyMongoError` → `ExternalServiceError`) | Mongo kapalı | Sohbet: nötr mesaj + 0 tarif. Deste: 502 → mobil "Yeniden dene" |

### Uç bazında sonuç

| Bağımlılık kapalı | Uç | Davranış |
|---|---|---|
| LLM | `POST /chat` | 200 · skorlama motorundan ilk 3 tarif · nötr mesaj · `degraded=true` |
| Görme | `POST /vision/meal` | 200 · boş tahmin (350 g orta) · `needs_manual_entry=true` · elle giriş kartı |
| Görme | `POST /chat` (fotoğraflı) | 200 · tespit yok · metin akışı devam eder |
| Görme | `POST /vision/ingredients` | 502 (sözleşme `list[...]`, bayrak taşıyamaz) → mobil elle malzeme aramaya düşer |
| Mongo | `GET /recipes/deck` | 502 → mobil nötr hata kartı; kiler/kalori/alışveriş çalışmaya devam eder |

Düşüş yanıtı **önbelleğe yazılmaz**: yoksa sağlayıcı geri geldikten sonra da
`CHAT_CACHE_TTL_MINUTES` boyunca düz yanıt servis edilirdi.

---

## 3. Değişen dosyalar

### Backend

| Dosya | Ne yapıldı |
|---|---|
| `app/core/circuit_breaker.py` | **Yeni.** Üç durumlu devre kesici (kapalı / açık / yarı açık) |
| `app/core/request_id.py` | **Yeni.** Her isteğe 8 karakterlik izlenebilir kimlik |
| `app/core/config.py` | `CIRCUIT_FAILURE_THRESHOLD`, `CIRCUIT_OPEN_SECONDS`, `DEGRADE_ON_PROVIDER_FAILURE` |
| `app/core/exceptions.py` | Hata gövdesine `request_id`; beklenmeyen hatada tip + kimlik loglanıyor; 123 satır ölü kod silindi |
| `app/main.py` | `install_request_id` bağlandı (en dışta) |
| `app/db/session.py` | `get_db`'ye açık `rollback` |
| `app/services/vision/providers.py` | `BrokenVisionProvider`; `max_tokens` ayardan okunuyor |
| `app/services/vision/base.py` | `InvalidImage` (400) sınıfı; `prepare_image` artık bunu fırlatıyor |
| `app/services/chat/providers.py` | `BrokenChatProvider` |
| `app/services/chat_rag.py` | `kural_tabanli_yanit()`; foto/aday/LLM düşüş blokları; `degraded` alanları |
| `app/services/meal_estimation.py` | `bos_tahmin()`; devre kontrolü; `VisionError` ve parse hatasında düşüş |
| `app/services/vision_ingredients.py` | Devre kesici; hata kodu yazımı düzeltildi |
| `app/routers/vision.py` | Mükerrer istisna sınıfları silindi |
| `app/schemas/chat.py`, `app/schemas/nutrition.py` | `degraded`, `degraded_reason` |
| `tests/test_resilience.py` | **Yeni.** 26 test |

### Mobil

| Dosya | Ne yapıldı |
|---|---|
| `lib/main.dart` | Dört hata kanalı da kapatıldı (aşağıda) |
| `lib/core/hata/hata_kaydi.dart` | **Yeni.** Tek hata kayıt noktası, son 50 hata bellekte |
| `lib/core/hata/guvenli.dart` | **Yeni.** `guvenliCalistir` — ateş-et-unut çağrıları için sarmalayıcı |
| `lib/widgets/hata_gorunumu.dart` | **Yeni.** `HataGorunumu` (ErrorWidget yerine), `HataDurumu`, `HataSatiriKucuk` |
| `lib/providers/shopping_provider.dart` | `isaretle` korumalı; hata olunca liste eski haline döner |
| `lib/widgets/calories/meal_add_flow.dart` | `pickImage` try içine alındı; `degraded` gelince elle giriş kartı |
| `lib/providers/chat_provider.dart` | `ChatEntry.degraded` |
| `lib/widgets/chat/message_bubble.dart` | "Kilerine göre seçildi" rozeti |
| `lib/screens/pantry/pantry_screen.dart` | Görme arızasında elle aramaya düşüş |
| 5 ekran + onboarding + arama tabakası | Kopyalanmış hata blokları `HataDurumu`/`HataSatiriKucuk`'e toplandı |
| `test/dayaniklilik_test.dart` | **Yeni.** 13 test |

### Flutter'daki dört hata kanalı

Birini atlarsan o kanaldan gelen hata hâlâ çökertir:

1. `FlutterError.onError` — build / layout / paint içindeki hatalar
2. `platformDispatcher.onError` — Flutter dışı async hatalar (motor katmanı)
3. `runZonedGuarded` — `unawaited` Future'lardan sızan hatalar
4. `ErrorWidget.builder` — çizim çöktüğünde gösterilen gövde

`ensureInitialized()` zone'un **içinde** çağrılıyor: binding'in kurulduğu zone ile
`runApp`'in zone'u farklı olursa Flutter uyarı üretir.

---

## 4. Bulunan hatalar ve durumu

| ID | Yer | Seviye | Sorun | Durum |
|---|---|---|---|---|
| B1 | `vision/providers.py` | **Major** | `max_tokens` sabit 1024 yazılmış, `VISION_MAX_TOKENS=6000` ölü ayar. Hata logu ölü ayarı yazdırıyordu ("6000 ile kesildi" derken gerçekte 1024). Uzun yanıtlar `finish_reason=length` ile kesilip 502 üretiyordu | ✅ Kapatıldı |
| B2 | `vision_ingredients.py` | **Major** | Hata kodu `cision_daily_limit` (yazım hatası) → istemci `code` ile dallanamıyordu | ✅ Kapatıldı |
| B3 | `routers/vision.py` | **Major** | `UnsupportedImageType`/`EmptyImage` import edilip hemen altında yeniden tanımlanıyordu; aynı hata iki farklı metinle dönebiliyordu | ✅ Kapatıldı |
| B4 | `vision/base.py` | **Major** | Okunamayan görüntü `VisionInvalidResponse` (502) fırlatıyordu; düşüş mantığı bunu "sağlayıcı çöktü" sanıp sessizce elle girişe düşürürdü | ✅ Kapatıldı (`InvalidImage`, 400) |
| B5 | `mobile/lib/main.dart` | **Kritik** | Hiçbir hata bariyeri yok: async hata = sessiz çökme / kırmızı ekran | ✅ Kapatıldı |
| B6 | `api_exception.dart` | Minor | `unknown_eror` ve "hata oluştur" yazım hataları | ✅ Kapatıldı |
| B7 | `main.py` | Minor | Gürültü listesinde `asynvio` yazılmış → `asyncio` logları susturulmuyordu | ✅ Kapatıldı |
| B8 | `core/exceptions.py` | Minor | 123 satır yorum satırına alınmış ölü kod | ✅ Kapatıldı |
| B9 | `meal_add_flow.dart` | **Major** | `pickImage` try bloğunun dışındaydı; galeri izni reddedilince buton sessizce hiçbir şey yapmıyordu (`unawaited` zincirinden kaçıyordu) | ✅ Kapatıldı |
| B10 | `shopping_provider.dart` | **Major** | `isaretle` hiçbir katmanda korunmuyordu; ağ hatasında kutucuk değişmiyor, mesaj çıkmıyordu — sessiz veri kaybı | ✅ Kapatıldı |
| B11 | `vision_ingredients.py` | Minor | `prepare_image` çağrısı yanlış girintiyle kota bloğunun içinde kalmıştı; `user_id=None` ile çağrıldığında `UnboundLocalError` | ✅ Kapatıldı (testle yakalandı) |

Kapatılmayan / bilerek bırakılan: yok.

---

## 5. Async çağrı denetimi (mobil)

```bash
cd mobile && grep -rn "unawaited(" lib/ --include=*.dart
```

28 çağrı noktasının hepsi tek tek incelendi. Ölçüt: *çağrılan fonksiyonun kendi
içinde `try/catch` ya da `AsyncValue.guard` var mı?*

- **26 nokta zaten korumalıydı** — ekranların çoğu `try/catch/finally` + `mounted`
  kontrolüyle yazılmıştı, provider'lar `AsyncValue.guard` kullanıyordu.
- **2 nokta korumasızdı**: B9 (`meal_add_flow.dart` → `pickImage`) ve
  B10 (`shopping_provider.dart` → `isaretle`). İkisi de kapatıldı.

Kalıcı çözüm olarak `guvenliCalistir` yardımcısı eklendi: hatayı hem `HataKaydi`'ye
yazıyor hem kullanıcıya nötr bir SnackBar gösteriyor ve `null` dönüyor.

---

## 6. Kanıt

### Otomatik (tekrar üretilebilir)

| Senaryo | Beklenen | Test | Sonuç |
|---|---|---|---|
| Görme %100 hata · `estimate_meal` | İstisna değil, `degraded` tahmin döner | `test_estimate_meal_gorme_cokunce_200_donuyor` | ✅ |
| Aynı yanıt şemadan geçiyor mu | `MealEstimate` doğrulaması geçer | `test_bos_tahmin_semaya_oturuyor` | ✅ |
| Devre açıkken | Sağlayıcıya hiç gidilmez | `test_estimate_meal_devre_acikken_saglayiciya_gitmiyor` | ✅ |
| LLM %100 hata | Kural tabanlı ilk 3 tarif | `test_kural_tabanli_yanit_ilk_ucu_secer` | ✅ |
| Mesaj nötr mü | "hata/çöktü/sunucu/API" geçmiyor | `test_kural_tabanli_yanit_notr_dil_kullanir` | ✅ |
| Bozuk dosya | 400, düşüşe uğramaz | `test_bozuk_dosya_400_veriyor_502_degil` | ✅ |
| Günlük kota | 429, düşüşe uğramaz | `test_gunluk_kota_hatasi_dis_servis_hatasi_degil` | ✅ |
| Acil geri alma anahtarı | `DEGRADE_ON_PROVIDER_FAILURE=false` → eski davranış | `test_dusus_kapatilabiliyor` | ✅ |
| Flutter çizim hatası | Kırmızı ekran değil, nötr kart | `ErrorWidget.builder` testi | ✅ |
| Ateş-et-unut hatası | Yutulur, `null` döner, **kaydedilir** | `guvenliCalistir` testleri | ✅ |

### Canlı prova (ekran görüntüsü gerekli — YAPILACAK)

`.env`'de `VISION_PROVIDER=broken` ve `CHAT_PROVIDER=broken` yapıp uygulamayı gez:

| # | Adım | Beklenen | Kanıt |
|---|---|---|---|
| 1 | Sohbet → "hafif bir şey öner" | Tarif kartları + "Kilerine göre seçildi" rozeti | `ekran-1.png` |
| 2 | Kalori → FAB → Kamera | Onay kartı boş adla açılıyor, kaydedilebiliyor | `ekran-2.png` |
| 3 | Kiler → Fotoğraf çek | "malzemeyi arayarak ekleyebilirsin" + arama diyaloğu | `ekran-3.png` |
| 4 | Sohbete 4 kez üst üste istek | Logda `Devre 'sohbet' ACILDI`; 4. yanıt belirgin şekilde hızlı | `log-1.txt` |
| 5 | `MONGODB_URI` bozuk → Keşfet | Nötr hata kartı + "Yeniden dene"; diğer sekmeler çalışıyor | `ekran-4.png` |

---

## 7. Bilinen sınırlar

- **Devre kesici süreç içidir.** Birden çok uvicorn worker'ı çalıştırıldığında her
  worker kendi sayacını tutar. Tek örnekli dağıtımda sorun yok; ölçeklenirse
  Redis gibi paylaşımlı bir sayaca taşınmalı.
- **`/vision/ingredients` sözleşmesi `list[DetectedIngredient]`** olduğu için düşüş
  bayrağı taşıyamıyor. Bu uçta düşüş istemci tarafında (elle malzeme arama)
  yapılıyor. Sözleşme bir gün nesneye çevrilirse sunucuya taşınabilir.
- **Mongo tamamen kapalıyken tarif önerisi üretilemez.** Kural tabanlı motor da
  adaylarını Mongo'dan çekiyor; bu durumda sohbet nötr bir mesajla 0 tarif döner.
  Gerçek bir çözüm için SQLite'ta küçük bir tarif yedeği tutmak gerekir — kapsam dışı.
- **`ErrorWidget.builder` yalnızca çizim hatalarını** karşılar; iş mantığı hataları
  yine ilgili ekranın `try/catch`'ine düşer.

---

## Tekrar üretme

```bash
cd backend && python -m pytest tests/ -q
```

```bash
cd mobile && flutter test
```

```bash
cd mobile && flutter analyze
```

Düşüş yollarını canlı görmek için `backend/.env`:

```dotenv
VISION_PROVIDER=broken
CHAT_PROVIDER=broken
```
