## 6. İndeks Kararları ve Gerekçeleri

### 6.1 Karar İlkeleri

Bu projede indeks eklerken üç kurala uyuldu:

1. **Her indeksin bir sahibi olmalı.** İndeks, adı belli bir sorguyu hızlandırmak
   için eklenir. "Belki lazım olur" diye eklenen indeks yoktur.
2. **Okuma hızı bedava değildir.** Her indeks, o tabloya yapılan her INSERT/UPDATE
   işlemini yavaşlatır ve disk alanı tüketir. Bu yüzden yazma yoğun tablolarda
   (`pantry_events`, `chat_messages`) indeks sayısı bilinçli olarak düşük tutuldu.
3. **Bileşik indekste sütun sırası kritiktir.** SQLite "en soldan önek"
   (leftmost prefix) kuralıyla çalışır: `(user_id, logged_date)` indeksi
   `WHERE user_id = ?` sorgusunu da hızlandırır, ama `WHERE logged_date = ?`
   sorgusunu hızlandırmaz. Bu yüzden her bileşik indekste **seçiciliği yüksek
   ve her sorguda mutlaka bulunan** sütun (`user_id`) başa alındı.

### 6.2 SQLite'a Özgü İki Not

- **UNIQUE kısıtı otomatik indeks üretir.** `email TEXT UNIQUE` yazıldığında
  SQLite arka planda bir indeks oluşturur; ayrıca `CREATE INDEX` yazmaya gerek yoktur.
  Aşağıdaki tabloda UNIQUE olarak işaretlenen satırlar bu şekilde çalışır.
- **Foreign key sütunları otomatik indekslenmez.** MySQL'in aksine SQLite,
  FK tanımladığında indeks oluşturmaz. Bu yüzden sık JOIN edilen FK sütunları
  (`products.ingredient_id`, `ingredient_aliases.ingredient_id`) elle indekslendi.

### 6.3 İndeks Tablosu

| # | Tablo | İndeks | Tip | Hangi sorguyu hızlandırır | Kullanan görev |
|---|---|---|---|---|---|
| 1 | `users` | `email` | UNIQUE | `WHERE email = ?` — her giriş denemesinde çalışır | W1-T08 |
| 2 | `user_diet_tags` | `(user_id, diet_tag_id)` | PK | Kullanıcının diyet etiketlerini çekme | W3-T04 |
| 3 | `user_allergens` | `(user_id, allergen_id)` | PK | Alerjen filtresi — güvenlik kritik yol | W3-T04 |
| 4 | `ingredients` | `canonical_name` | UNIQUE | `WHERE canonical_name IN (...)` — **sistemin en sık çalışan sorgusu**; her tarif eşleştirmesi, her kiler ekleme, her malzeme durum kontrolü buradan geçer | W3-T02, W3-T03, W4-T01 |
| 5 | `ingredients` | `category_id` | NORMAL | Kategoriye göre malzeme listeleme (öneri ekranı) | W2-T06 |
| 6 | `ingredient_aliases` | `alias` | UNIQUE | Bulanık eşleşmeden **önce** denenen tam eşleşme. Bu indeks olmadan rapidfuzz her seferinde tüm sözlüğü taramak zorunda kalır | W3-T02 |
| 7 | `ingredient_aliases` | `ingredient_id` | NORMAL | Bir malzemenin tüm takma adlarını çekme (yönetim ekranı) | W3-T16 |
| 8 | `unmatched_ingredients` | `normalized_text` | UNIQUE | Upsert: kayıt varsa `occurrence_count` artır, yoksa ekle. Tekilliği de garanti eder | W3-T02A |
| 9 | `unmatched_ingredients` | `occurrence_count` | NORMAL | `ORDER BY occurrence_count DESC LIMIT 20` — sözlüğe eklenecek adayların sıralanması | W3-T02A |
| 10 | `products` | `barcode` | UNIQUE | Barkod önbelleği kontrolü. Bu indeks sayesinde aynı barkod ikinci kez okunduğunda Open Food Facts'e istek gitmez | W2-T03, W2-T04 |
| 11 | `products` | `ingredient_id` | NORMAL | Ürün → jenerik malzeme çözümlemesi (FK, otomatik indekslenmez) | W2-T04 |
| 12 | `products` | `name` | NORMAL | Gıda arama ekranındaki metin araması | W2-T14 |
| 13 | `pantry_items` | `(user_id, ingredient_id)` | UNIQUE | Çift görev: (a) kullanıcı başına malzeme başına tek satır garantisi, (b) upsert ve kiler-tarif eşleştirme sorgusu | W2-T01, W2-T02, W4-T01 |
| 14 | `pantry_items` | `(user_id, is_active)` | NORMAL | Kiler listesi ekranı yalnızca aktif ürünleri çeker | W2-T06 |
| 15 | `pantry_items` | `expiry_date` | NORMAL | `WHERE expiry_date <= date('now','+3 day')` — SKT taraması tüm kullanıcılar için toplu çalıştığı için `user_id` başa konmadı | W4-T07 |
| 16 | `pantry_events` | `(user_id, created_at)` | NORMAL | Zaman aralığı sorguları: aylık israf raporu, hareket geçmişi | V2 raporlama |
| 17 | `pantry_events` | `(user_id, ingredient_id, created_at)` | NORMAL | Tüketim hızı tahmini: belirli bir malzemenin son 30 günlük hareketleri | V2 öngörülü liste |
| 18 | `pantry_events` | `(user_id, event_type)` | NORMAL | `WHERE event_type = 'bozuldu_atildi'` — israf toplamı | V2 israf raporu |
| 19 | `shopping_list_items` | `(user_id, ingredient_id)` | UNIQUE | Mükerrer eklemeyi engeller, miktar birleştirme (upsert) yapılmasını sağlar | W2-T15, W2-T16 |
| 20 | `shopping_list_items` | `(user_id, is_checked)` | NORMAL | Liste ekranı işaretlenmemiş kayıtları çeker | W4-T06 |
| 21 | `meal_logs` | `(user_id, logged_date)` | NORMAL | **Kalori ekranının her açılışında** çalışan günlük toplam sorgusu. Uygulamanın en sık çalışan ikinci sorgusu | W2-T12, W2-T13 |
| 22 | `meal_logs` | `(user_id, logged_date, meal_type)` | NORMAL | Öğün bazlı gruplama (kahvaltı/öğle/akşam kırılımı) | W2-T13 |
| 23 | `weight_logs` | `(user_id, logged_date)` | UNIQUE | Günde tek kilo kaydı garantisi + grafik sorgusu | Opsiyonel |
| 24 | `recipe_feedback` | `(user_id, recipe_id)` | NORMAL | "Bu tarifi beğenmiş miyim?" kontrolü, tarif detay ekranında | W3-T06 |
| 25 | `recipe_feedback` | `(user_id, created_at)` | NORMAL | Öğrenme döngüsünün son N geri bildirimi çekmesi | W3-T06 |
| 26 | `recipe_favorites` | `(user_id, recipe_id)` | PK | Favori listesi + tekillik | Opsiyonel |
| 27 | `user_taste_weights` | `(user_id, dimension, taste_key)` | UNIQUE | Her geri bildirimde upsert yapılır; skorlamada tüm vektör tek sorguda çekilir | W3-T05, W3-T06 |
| 28 | `chat_conversations` | `(user_id, last_message_at)` | NORMAL | Sohbet listesi, en yeniden eskiye | W3-T14 |
| 29 | `chat_messages` | `(conversation_id, created_at)` | NORMAL | Sohbet geçmişinin sıralı yüklenmesi | W3-T14 |
| 30 | `llm_cache` | `cache_key` | UNIQUE | **Her chatbot isteğinde ilk kontrol.** Önbellek isabeti bu indekse bağlı; yavaş olursa önbelleğin anlamı kalmaz | W3-T13 |
| 31 | `llm_cache` | `expires_at` | NORMAL | Süresi dolmuş kayıtların toplu temizliği | W3-T13 |

### 6.4 MongoDB İndeksleri

| # | Alan | Tip | Gerekçe |
|---|---|---|---|
| 1 | `ingredients.canonical_name` | Multikey | Dizi içindeki alan. `$setIntersection` ile kiler eşleştirmesi bu indeksten yararlanır |
| 2 | `diet_tags` | Multikey | `$in` filtresi (vegan, glutensiz) |
| 3 | `calories_per_serving` | Normal | Kalan kaloriye göre `$lte` süzme |
| 4 | `(diet_tags, calories_per_serving)` | Bileşik | En sık kullanılan filtre kombinasyonu: "vegan **ve** 500 kcal altı" |
| 5 | `allergens` | Multikey | `$nin` filtresi — güvenlik kritik yol |

### 6.5 Bilinçli Olarak İndekslenmeyenler

| Alan | Neden indekslenmedi |
|---|---|
| `meal_logs.recipe_id` | Bu sütun üzerinden arama yapılmıyor; yalnızca izlenebilirlik referansı |
| `pantry_events.pantry_item_id` | Sorgular hep `user_id` + `ingredient_id` üzerinden; bu FK yalnızca izlenebilirlik için |
| `recipe_feedback.recipe_id` (tek başına) | `(user_id, recipe_id)` bileşik indeksi zaten var; ayrıca "bu tarifi kaç kişi beğendi" gibi global bir sorgu MVP'de yok |
| `users.created_at` | Yönetim raporu MVP kapsamında değil |
| Tüm `updated_at` sütunları | Hiçbir sorgu bu alanlara göre filtrelemiyor |
| `categories`, `diet_tags`, `allergens` (kod dışı alanlar) | Bu tablolar 10-30 satır; SQLite tam tarama yapsa bile ölçülebilir bir maliyet oluşmaz |

### 6.6 Doğrulama Yöntemi (W4-T10)

İndekslerin gerçekten kullanıldığı varsayılmadı, **ölçüldü**. Her kritik sorgu için:

```sql
EXPLAIN QUERY PLAN
SELECT * FROM meal_logs WHERE user_id = 1 AND logged_date = '2026-08-03';
```

Çıktıda `SEARCH ... USING INDEX ...` görülmelidir.
`SCAN meal_logs` görülüyorsa indeks kullanılmıyor demektir ve sorgu ya da indeks
yeniden düzenlenmiştir.

Ayrıca backend'e bir zamanlama middleware'i eklendi; 200 ms'yi aşan her sorgu
uyarı seviyesinde loglanır. Hedef: ana listeleme uçlarında p95 < 500 ms.

## 7. SQLite ↔ MongoDB Birleştirme Stratejisi

### 7.1 Problem

Melez (hybrid) mimari kullanıldığı için **iki veritabanı arasında JOIN yapılamaz.**
SQLite kullanıcı, kiler ve kalori verisini; MongoDB tarif verisini tutar. Ancak
uygulamanın çekirdek sorusu tam da bu ikisinin kesişiminde:

> "Kilerimdeki malzemelerle, kalori hedefimi aşmadan hangi tarifleri yapabilirim?"

Bu birleştirme **veritabanı katmanında değil, uygulama (servis) katmanında** yapılır.

### 7.2 İki Birleştirme Anahtarı

| # | Anahtar | SQLite tarafı | MongoDB tarafı | Yön |
|---|---|---|---|---|
| 1 | `canonical_name` | `ingredients.canonical_name` (TEXT UNIQUE) | `recipes.ingredients[].canonical_name` (String) | Malzeme eşleştirme |
| 2 | `recipe_id` | `meal_logs.recipe_id`, `recipe_feedback.recipe_id`, `recipe_favorites.recipe_id`, `shopping_list_items.source_recipe_id`, `pantry_events.recipe_id` (hepsi TEXT) | `recipes._id` (ObjectId) | Tarif referansı |

### 7.3 Anahtar 1: `canonical_name`

**Format kuralları** (ihlal edilirse eşleştirme sessizce başarısız olur):

- Yalnızca `[a-z0-9_]` — küçük harf, rakam ve alt çizgi
- **Türkçe karakter kullanılmaz**: `kirmizi_mercimek` ✓ · `kırmızı_mercimek` ✗
  Gerekçe: MongoDB'de collation farkları, JSON dışa aktarımı ve URL kullanımı
  sırasında Türkçe karakterler tutarsızlık yaratır
- Boşluk yerine alt çizgi, çoğul yerine tekil: `yesil_biber`, `sogan`
- Tek doğruluk kaynağı **SQLite `ingredients` tablosudur.** MongoDB'deki değer
  bu tablonun denormalize (kopya) halidir

**Neden `ingredient_id` (sayı) değil de metin?**

MongoDB dokümanları SQLite'ın otomatik artan ID'lerine bağımlı olmamalıdır.
Veritabanı sıfırlanıp yeniden seed edildiğinde ID'ler değişebilir ama
`canonical_name` sabit kalır. Ayrıca tarif JSON'ları insan tarafından okunabilir
ve elle düzenlenebilir olur.

**Veri akışı — Senaryo: "Kilerimde ne pişirebilirim?" (W3-T03)**

```
1. SQLite : SELECT i.canonical_name
            FROM pantry_items p JOIN ingredients i ON i.id = p.ingredient_id
            WHERE p.user_id = ? AND p.is_active = 1 AND p.quantity_base > 0
            -> ["kirmizi_mercimek", "sogan", "havuc", "zeytinyagi"]

2. Uygulama: is_staple = true olan malzemeler (tuz, su, karabiber) listeye eklenir

3. MongoDB : aggregation pipeline
             $addFields: eslesen = $setIntersection(recipe_malzemeleri, kiler_listesi)
             $addFields: match_ratio = size(eslesen) / size(recipe_malzemeleri)
             $match  : diet_tags $in kullanici_diyetleri
             $match  : allergens $nin kullanici_alerjenleri
             $match  : calories_per_serving <= kalan_kalori
             $sort   : match_ratio DESC
             $limit  : 20

4. Uygulama: skorlama (W3-T05) uygulanır, sonuç istemciye döner
```

Dikkat: adım 1 SQLite'ta, adım 3 MongoDB'de çalışır. Aralarındaki tek bağ
**string dizisidir**; veritabanı seviyesinde bir ilişki yoktur.

### 7.4 Anahtar 2: `recipe_id`

**Saklama kuralı:** MongoDB `_id` alanı `ObjectId` tipindedir; SQLite tarafında
her zaman **`str(ObjectId)` yani 24 karakterlik onaltılık metin** olarak saklanır.

```python
# Yazarken
recipe_id_text = str(recipe["_id"])          # "66f1a2b3c4d5e6f7a8b9c0d1"

# Okurken
from bson import ObjectId
if not ObjectId.is_valid(recipe_id_text):
    raise NotFoundError("Gecersiz tarif kimligi.")
recipe = await db.recipes.find_one({"_id": ObjectId(recipe_id_text)})
```

`ObjectId` nesnesi asla doğrudan SQLite'a yazılmaz — SQLAlchemy onu serileştiremez.

### 7.5 Bütünlük (Referential Integrity) Nasıl Sağlanıyor?

Veritabanı motoru bu iki taraf arasında bütünlüğü **zorlayamaz.** Yabancı anahtar
kısıtı yoktur, CASCADE çalışmaz. Bu boşluk üç uygulama katmanı kuralıyla kapatıldı:

**Kural 1 — Yazmadan önce doğrula.**
`recipe_id` içeren bir kayıt oluşturulmadan önce ilgili tarifin MongoDB'de var
olduğu kontrol edilir. Yoksa `NotFoundError` fırlatılır.

**Kural 2 — Okurken yetim kayda dayanıklı ol.**
Bir tarif MongoDB'den silinirse `recipe_feedback` ve `meal_logs` kayıtları yetim
kalır. Bu kayıtlar **silinmez** (geçmiş bozulmamalı); arayüzde "Bu tarif artık
mevcut değil" olarak gösterilir. `meal_logs` zaten anlık görüntü ilkesiyle
`item_name` ve `calories` alanlarını kopyaladığı için kalori geçmişi bundan
etkilenmez.

**Kural 3 — Malzeme eşleşmezse sessizce yutma.**
MongoDB'deki bir `canonical_name` SQLite `ingredients` tablosunda bulunamazsa
malzeme **GRİ** olarak gösterilir ve metin `unmatched_ingredients` tablosuna
yazılır (W3-T02A). Böylece tutarsızlık kaybolmaz, ölçülebilir hale gelir.

### 7.6 Tutarlılık Denetim Betiği

`backend/scripts/check_schema_consistency.py` dosyası iki tarafı karşılaştırır ve
tutarsızlıkları raporlar. Seed sonrası ve her hafta sonu çalıştırılır.

```python
"""SQLite ve MongoDB arasindaki birlestirme anahtarlarinin tutarliligini denetler."""
import asyncio

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorClient
from sqlalchemy import select

from app.core.config import settings
from app.db.session import SessionLocal
from app.models import Ingredient, MealLog, RecipeFeedback


async def main() -> None:
    mongo = AsyncIOMotorClient(settings.MONGODB_URI)[settings.MONGODB_DB_NAME]

    with SessionLocal() as db:
        sqlite_names = {row[0] for row in db.execute(select(Ingredient.canonical_name))}

        # 1) MongoDB'de olup SQLite sozlugunde olmayan malzemeler -> GRI gorunecekler
        mongo_names: set[str] = set()
        async for recipe in mongo.recipes.find({}, {"ingredients.canonical_name": 1}):
            for ing in recipe.get("ingredients", []):
                if name := ing.get("canonical_name"):
                    mongo_names.add(name)

        eksik_sozlukte = sorted(mongo_names - sqlite_names)

        # 2) Hicbir tarifte kullanilmayan sozluk kayitlari (zararsiz ama bilgi)
        kullanilmayan = sorted(sqlite_names - mongo_names)

        # 3) SQLite'ta referans verilen ama MongoDB'de olmayan tarifler -> yetim kayitlar
        referanslar: set[str] = set()
        referanslar |= {r[0] for r in db.execute(select(MealLog.recipe_id)) if r[0]}
        referanslar |= {r[0] for r in db.execute(select(RecipeFeedback.recipe_id)) if r[0]}

        yetim = []
        for rid in referanslar:
            if not ObjectId.is_valid(rid):
                yetim.append((rid, "gecersiz ObjectId"))
                continue
            if not await mongo.recipes.find_one({"_id": ObjectId(rid)}, {"_id": 1}):
                yetim.append((rid, "MongoDB'de bulunamadi"))

    print(f"Sozlukteki malzeme sayisi        : {len(sqlite_names)}")
    print(f"Tariflerde gecen malzeme sayisi  : {len(mongo_names)}")
    print(f"Sozlukte EKSIK (gri gorunecek)   : {len(eksik_sozlukte)}")
    for name in eksik_sozlukte[:20]:
        print(f"   - {name}")
    print(f"Hicbir tarifte kullanilmayan     : {len(kullanilmayan)}")
    print(f"Yetim tarif referansi            : {len(yetim)}")
    for rid, sebep in yetim[:20]:
        print(f"   - {rid}: {sebep}")

    kapsama = 1 - len(eksik_sozlukte) / len(mongo_names) if mongo_names else 0
    print(f"\nSOZLUK KAPSAMA ORANI: %{kapsama * 100:.1f}  (hedef: %90 uzeri)")


if __name__ == "__main__":
    asyncio.run(main())
```

**Hedef metrik:** Sözlük kapsama oranı **%90'ın üzerinde**. Altına düşerse
`unmatched_ingredients` tablosundaki en sık kayıtlar sözlüğe eklenir (W3-T16).

### 7.7 Neden Tek Veritabanı Kullanılmadı?

| Alternatif | Neden tercih edilmedi |
|---|---|
| Her şey SQLite'ta | Tarif malzemeleri ve adımları değişken uzunlukta iç içe yapılardır. İlişkisel modelde `recipe_ingredients` + `recipe_steps` tabloları gerekir; her tarif kartı için 3 JOIN yapılır ve `$setIntersection` benzeri küme işlemleri elle yazılır |
| Her şey MongoDB'de | Kullanıcı, kiler ve kalori verisi güçlü ilişkisel yapıdadır: transaction, foreign key, CASCADE ve toplama (SUM/GROUP BY) sorguları gerektirir. Bunlar ilişkisel veritabanının doğal işidir |
| **Melez (seçilen)** | Her veri kendi doğasına uygun motorda tutulur. Bedeli: JOIN yapılamaması. Bu bedel, yukarıdaki üç uygulama kuralı ve tutarlılık denetim betiğiyle yönetilebilir düzeyde tutuldu |