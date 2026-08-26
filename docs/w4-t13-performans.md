# API Performansı ve İndeksleme (W4-T13)

**Tarih:** 2026-08-26 &nbsp;|&nbsp; **Tekrar:** 30 &nbsp;|&nbsp; **Ölçüm:** süreç içi (TestClient) — ağ ve uvicorn payı hariç


**Kabul kriteri 1 — deste ucu p95 < 800 ms: GEÇTİ (37.3 ms)**

**Kabul kriteri 2 — görme modeli p95 < 6 sn: GEÇTİ (1.74 sn)**


## 1. Uç gecikmeleri

| Uç | n | p50 (ms) | p95 (ms) | p99 (ms) | En yüksek | Sorgu (min–maks) |
|---|---|---|---|---|---|---|
| `GET /recipes/deck` | 30 | 25.8 | **37.3** | 43.3 | 43.3 | 12–12 |
| `GET /pantry` | 30 | 4.7 | **6.9** | 9.8 | 9.8 | 1–1 |
| `GET /shopping` | 30 | 3.5 | **7.0** | 57.6 | 57.6 | 1–1 |
| `GET /meals/daily` | 30 | 2.6 | **5.2** | 5.7 | 5.7 | 1–1 |
| `GET /catalog/ingredients` | 30 | 3.7 | **6.5** | 6.6 | 6.6 | 1–1 |
| `GET /recipes/cards` | 30 | 4.6 | **9.8** | 9.9 | 9.9 | 0–0 |
| `GET /recipes/{id}` | 30 | 2.3 | **3.9** | 3.9 | 3.9 | 0–0 |

Sorgu sayısı sütunu N+1 göstergesidir: veri büyürken bu sayı sabit kalmalı. Artıyorsa ilgili serviste `joinedload` eksik demektir.


## 2. İndeks kullanımı (EXPLAIN QUERY PLAN)

| Sorgu | Plan | Durum |
|---|---|---|
| kiler listesi (user_id + availability) | `SEARCH pantry_items USING INDEX ix_pantry_user_updated (user_id=?)` | ✅ indeks |
| kiler tekil (user_id + ingredient_id) | `SEARCH pantry_items USING INDEX sqlite_autoindex_pantry_items_1 (user_id=? AND ingredient_id=?)` | ✅ indeks |
| malzeme sozlugu (canonical_name) | `SEARCH ingredients USING INDEX ix_ingredients_canonical_name (canonical_name=?)` | ✅ indeks |
| alisveris listesi (user_id + created_at) | `SEARCH shopping_list_items USING INDEX ix_shopping_user_created (user_id=?)` | ✅ indeks |
| yapacaklarim (user_id + action + created_at) | `SEARCH recipe_feedback USING INDEX ix_feedback_user_action_time (user_id=? AND action=? AND created_at>?)` | ✅ indeks |
| kalici eleme (user_id + reason) | `SEARCH recipe_feedback USING INDEX ix_feedback_user_reason_time (user_id=? AND reason=?)` | ✅ indeks |
| gunluk ogun ozeti (user_id + logged_date) | `SEARCH meal_logs USING INDEX ix_meals_user_date (user_id=? AND logged_date=?)` | ✅ indeks |

## 3. Görsel yükleme boyutu

`VISION_MAX_IMAGE_PX=900`, `VISION_JPEG_QUALITY=80`

| Ölçüm | Değer |
|---|---|
| Fotoğraf | 4 |
| Ortalama ham boyut | 2926.3 KB |
| Ortalama gönderilen boyut | 62.5 KB |
| Küçültme oranı | 46.8× |
| Sıkıştırma p95 | 126.4 ms |

## 4. Görme modeli yanıt süresi

Kaynak: `vision_requests` tablosu, sağlayıcı `groq`, model `qwen/qwen3.6-27b`.

| Ölçüm | Değer |
|---|---|
| Başarılı çağrı | 26 |
| p50 | 1251 ms |
| **p95** | **1735 ms** |
| p99 | 12444 ms |
| Ortalama gönderilen görsel | 77.4 KB |

## Bilinen sınırlar

- Skorlama pipeline'ındaki `max_total_minutes` filtresi `$expr` kullanır ve **indeks kullanamaz**. Tarif sayısı yüz binlere çıkarsa dokümana `total_time` alanı eklenip indekslenmeli.

- Ölçüm süreç içidir; ağ gecikmesi ve uvicorn payı dahil değildir.


## Tekrar üretme

```bash
cd backend && python -m scripts.measure_api_performance --rapor ../docs/w4-t13-performans.md
```
