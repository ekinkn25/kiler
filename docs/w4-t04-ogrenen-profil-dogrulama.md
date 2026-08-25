# W4-T04 — Öğrenen Profil Motorunun Gerçek Veriyle Doğrulanması

**Tarih:** 2026-08-25
**Kapsam:** W3-T02B'de kurulan `UserTasteWeight` motoru
**Ölçüm aracı:** `backend/scripts/verify_taste_engine.py`
**Regresyon testi:** `backend/tests/test_taste_convergence.py`

---

## 1. Yöntem

Ölçüm sentetik ağırlık enjeksiyonuyla değil, **gerçek HTTP akışıyla** yapıldı.
Script `taste_lab@example.com` test kullanıcısını sıfırlar, kilerine 6 sabit
malzeme koyar ve üretimdeki uçlardan geçerek swipe atar:

```
GET  /api/v1/recipes/deck        → 10 kartlık deste
GET  /api/v1/recipes/{id}        → kararı vermek için malzeme listesi
POST /api/v1/recipes/{id}/swipe  → sinyal
```

Böylece router → `swipe_service` → `taste_service` zincirinin tamamı
gerçekten çalışır; motorun testte farklı, üretimde farklı davranma ihtimali
kalmaz.

**Sabit zevk profili:** bakliyat/sebze sever, kırmızı et sevmez.

| Karar | Kural |
|---|---|
| `yaptim` | `patlican, bulgur, kabak, kuru_fasulye, nohut, kirmizi_mercimek, ispanak` içeren **ve** `difficulty=kolay` |
| `begendim` | Aynı malzemeler, zorluk kolay değil |
| `begenmedim` + `sevmedim` | `kiyma, dana_eti, sucuk, kuzu_eti` içeren |
| (sinyal yok) | Diğerleri — kullanıcı kartı geçti |

`tuz`/`su` gibi 110 tarifin 90'ında geçen malzemeler bilerek profile
alınmadı: ayırt edici olmayan anahtar zevk vektörünü bilgilendirmez.

**Karşılaştırma kurulumu:** zevk KAPALI durumu `ScoringContext.taste`
boşaltılarak üretilir. Kiler, kalori ve süre bileşenleri iki koşulda da
birebir aynıdır; ölçülen fark **yalnızca** öğrenen profilden gelir.

---

## 2. Başlangıç durumu: motor sıralamayı hiç değiştirmiyordu

30 öğrenen sinyal (13 `yaptim`, 6 `begendim`, 11 `sevmedim`) sonrası:

```
#   ZEVK ACIK                    skor     zevk   | ZEVK KAPALI                skor
1   Zeytinyağlı Barbunya         0.7403   1.0    | Zeytinyağlı Barbunya       0.6403
2   Domates Dolması              0.6791   1.0    | Domates Dolması            0.5791
3   Zeytinyağlı Pırasa           0.6658   1.0    | Zeytinyağlı Pırasa         0.5658
4   Domates Soslu Makarna        0.6483   1.0    | Domates Soslu Makarna      0.5483
5   Kabak Dolması                0.6472   1.0    | Kabak Dolması              0.5472
```

İki liste **birebir aynı**, aradaki fark her satırda sabit `+0.1000`.

Sebep zincirleme üç kusurdu:

### Kusur 1 — Zevk skoru tavana yapışıyordu (asıl neden)

`_zevk_ham` eşleşen ağırlıkların **toplamı**ydı ve `[-1, 1]` aralığına
kırpılıyordu. Bir tarifte `cuisine` + `difficulty` + `diet_tag` + ~8 zorunlu
malzeme eşleştiği için ham toplam rahatça 5-8'e çıkıyor, kırpma sonrası
110 tarifin **105'i tam 1.0** oluyordu.

`_s_zevk = 1.0` → katkı `0.20 × 1.0 = 0.20` → normalize edilmiş halde her
tarife sabit `+0.10`. Yani zevk bileşeni bir **sabit terim**e dönüşmüştü:
sıfır ayırt edicilik.

Yan etki: 40 malzemeli tarif, 3 malzemeli tarifi salt uzunluğu yüzünden
eziyordu.

### Kusur 2 — `yaptim = 3 kat` pratikte çalışmıyordu

`swipe_service` `yaptim` için `register_recipe_signal(..., tekrar=3)`
gönderiyordu. Ama `tekrar`, aynı örnek-ortalaması güncellemesini üç kez
koşturuyordu:

```
weight += (signal - weight) / event_count
```

Sabit sinyalde bu güncelleme sinyalin kendisine yakınsar. Üç kez koşmak
yalnızca yakınsamayı hızlandırır, **tavanı değiştirmez** — `yaptim` ile
`begendim` aynı nihai ağırlığı (1.0) üretiyordu. Ek olarak `event_count`
gerçek swipe sayısının 3 katına şişiyordu (30 sinyal → 671 olay).

### Kusur 3 — Zevk değişimi takip edilemiyordu

Örnek ortalamasında n. sinyal ağırlığı yalnızca `1/n` kadar oynatır.
50 kart sonra kullanıcı fikir değiştirse motor bunu pratikte takip edemez.
Ölçümde ağırlık satırlarının **%55.8'i tam ±1.0**'a yapışmıştı.

---

## 3. Yapılan düzeltmeler

### 3.1 `taste_service.py` — sönümlü (üstel) ortalama

```python
TASTE_ALPHA = 0.20
STRENGTH_BEGENDIM = 1.0
STRENGTH_YAPTIM   = 3.0
STRENGTH_SEVMEDIM = 1.0

alpha = min(1.0, max(TASTE_ALPHA, 1.0 / event_count) * strength)
weight += alpha * (signal - weight)
```

Üç tasarım kararı:

- **`max(TASTE_ALPHA, 1/n)` — soğuk başlangıç düzeltmesi.** İlk olayda
  `α = 1` olduğu için ağırlık eskisi gibi doğrudan sinyale eşitlenir, sonra
  sabit `0.20`'ye oturur. Bu olmasaydı tek kart beğenen kullanıcıda ağırlık
  `1.0` yerine `0.20`'de kalır, zevk vektörü neredeyse hiç konuşmazdı.
- **Güç sinyal değerine değil sönüm hızına uygulanır.** Sinyali `3.0` yapmak
  ağırlığı `CheckConstraint("weight BETWEEN -1 AND 1")` dışına taşırırdı.
  Hızı 3 katlamak aynı "daha çok önemse" etkisini aralığı bozmadan verir.
- **Konveks birleşim aralığı garanti eder.** `signal` ve `weight` `[-1,1]`
  içindeyse sonuç da öyle kalır; kısıt kod tarafında sağlanır.

`tekrar` parametresi kaldırıldı, yerine `strength` geldi. `event_count`
artık gerçek sinyal sayısını taşır.

### 3.2 `recipe_scoring.py` — toplam yerine ortalama

`$reduce` biriktiricisi `{toplam, adet}` taşıyacak şekilde değiştirildi:

```python
"_zevk_ham": {"$cond": [
    {"$eq": ["$_zevk.adet", 0]}, 0.0,
    {"$divide": ["$_zevk.toplam", "$_zevk.adet"]},
]}
```

Kırpma güvenlik ağı olarak duruyor ama artık devreye girmiyor.
Hiç eşleşme yoksa `0` (nötr) → `_s_zevk = 0.5`, yani yeni kullanıcı
cezalandırılmaz.

### 3.3 Açıklanabilirlik

`score_breakdown` çıktısına `taste_matched` eklendi: zevk skorunun kaç
öğrenilmiş anahtardan hesaplandığı. `0` ise motor o tarif hakkında henüz
bir şey bilmiyordur — bu, "nötr buluyor" durumundan artık ayırt edilebilir.

---

## 4. Sonuçlar

Her iki koşu da 30 öğrenen sinyal, aynı kiler, aynı profil, 110 tarif.

| Ölçüm | Önce | Sonra |
|---|---|---|
| **İlk 10'da konum değişimi** | **0 / 10** | **8 / 10** |
| Zevk skoru eşsiz değer | 8 / 110 | **105 / 110** |
| Zevk skoru aralığı | [0.7249, **1.0**] tavan | [0.2768, 0.7583] |
| Zevk skoru ortalaması | 0.9872 | 0.5201 |
| Ortalama sıra kayması | 2.16 | **6.49** |
| Yer değiştiren tarif | 76 / 110 | **105 / 110** |
| Spearman ρ | 0.9870 | 0.9626 |
| Kendall τ | 0.9600 | 0.8492 |
| `event_count` toplamı | 671 (şişik) | 352 (gerçek) |

Düzeltme sonrası ilk 10:

```
#   ZEVK ACIK                    skor     zevk     | ZEVK KAPALI                skor
1    Zeytinyağlı Barbunya        0.6658   0.6275   | Zeytinyağlı Barbunya       0.6403
2   *Zeytinyağlı Pırasa          0.5969   0.6556   | Domates Dolması            0.5791
3   *Domates Soslu Makarna       0.5803   0.6603   | Zeytinyağlı Pırasa         0.5658
4   *Domates Dolması             0.5754   0.4817   | Domates Soslu Makarna      0.5483
5    Kabak Dolması               0.5595   0.5615   | Kabak Dolması              0.5472
6   *Patlıcan Kızartması         0.5513   0.6783   | Zeytinyağlı Taze Fasulye   0.5273
7   *Zeytinyağlı Taze Fasulye    0.5493   0.6102   | Ispanaklı Börek            0.5164
8   *Sebzeli Bulgur Pilavı       0.5480   0.6689   | Patlıcan Kızartması        0.5157
9   *Fasulye Pilaki              0.5468   0.6929   | Sebzeli Bulgur Pilavı      0.5142
10  *Ispanaklı Börek             0.5403   0.6191   | Fırın Sütlaç               0.5104
```

Zevk sütunu artık 0.48–0.69 arasında gerçek bir dağılım gösteriyor.
`Fırın Sütlaç` ilk 10'dan düştü, yerine `Fasulye Pilaki` girdi — profil
tatlıya değil bakliyata sinyal vermişti.

### Kabul kriteri eşikleri

Spearman/Kendall bilgi amaçlıdır, kriter değildir: 110 tarifin tamamı
skorlandığında alt sıralardaki küçük oynamalar korelasyonu yüksek tutar,
oysa kullanıcı yalnızca ilk ekranı görür. Kriter iki somut ölçüye bağlandı:

- İlk 10 konumun en az **3**'ünde farklı tarif → ölçülen: **8** ✔
- Zevk skoru tariflerin yarısından fazlasında eşsiz → ölçülen: **0.95** ✔

Script çıktısı: **8 kontrol, 0 başarısız.**

---

## 5. Açık kalan bulgular

**`cuisine` boyutu bu veri setinde ölü ağırlık.** Mongo'daki 110 tarifin
tamamı `cuisine="turk"`. Anahtar her tarifle eşleştiği için sıfır ayırt
edicilik taşıyor, ama ortalamaya giriyor ve sönümlü ortalama altında son
sinyallere göre salınıyor (ölçümde `+0.607` → `-0.346`). Tarif havuzuna
başka mutfaklar eklenene kadar zararsız; eklenmezse skorlamada tek değerli
boyutları atlamak düşünülebilir.

**Ayırt edici olmayan malzemeler hâlâ ortalamaya giriyor.** `tuz` 90,
`su` 70 tarifte geçiyor ve kullanıcının genel eğilimine göre pozitif ağırlık
kazanıyor. Şu an her tarifi benzer biçimde kaydırdığı için sıralamayı
bozmuyor, ama IDF benzeri bir seyreklik ağırlığı ayrımı daha da keskinleştirir.

**`TASTE_ALPHA = 0.20` deneysel olarak seçildi.** Yarı ömrü ~3 olay.
Küçültmek motoru muhafazakâr, büyütmek oynak yapar. Daha fazla gerçek
kullanıcı verisi biriktiğinde yeniden ayarlanmalı.

---

## 6. Tekrar üretme

```bash
cd backend && .venv/Scripts/python.exe -m scripts.verify_taste_engine --swipe 30
```

MongoDB bağlantısı ve seed edilmiş tarifler gerekir. Script kendi test
kullanıcısını sıfırlayıp kurar; başka kullanıcının verisine dokunmaz.
`--json <yol>` ile ölçüm çıktısı makine okunur biçimde kaydedilir,
`--etiket` ile koşu adlandırılır.

Tablodaki "Önce" sütunu düzeltme öncesi koda aittir; bu commit'in
ebeveyninde aynı komut çalıştırılarak yeniden üretilebilir.

Bağlantı gerektirmeyen regresyon testleri:

```bash
cd backend && .venv/Scripts/python.exe -m pytest tests/test_taste_convergence.py -q
```

---

## 7. Değişen dosyalar

| Dosya | Değişiklik |
|---|---|
| `app/services/taste_service.py` | Örnek ortalaması → sönümlü ortalama; `tekrar` → `strength` |
| `app/services/swipe_service.py` | `yaptim` için `strength=STRENGTH_YAPTIM` |
| `app/services/recipe_scoring.py` | `_zevk_ham` toplam → ortalama; `taste_matched` çıktısı |
| `app/schemas/recipe.py` | `ScoreBreakdown.taste_matched` alanı |
| `scripts/verify_taste_engine.py` | **Yeni** — ölçüm ve doğrulama scripti |
| `tests/test_taste_convergence.py` | **Yeni** — yakınsama regresyon testleri |
| `tests/test_taste_service.py` | `tekrar` testi `strength` davranışına güncellendi |
| `tests/test_recipe_scoring.py` | `_zevk` yapısı ve `taste_matched` için güncellendi |
