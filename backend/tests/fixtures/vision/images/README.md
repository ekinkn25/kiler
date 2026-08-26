# Görme modeli test fotoğrafları

Bu klasör bilerek boş bırakıldı — fotoğraflar `.gitignore` ile hariç tutulur
(EXIF konum bilgisi + ikili dosya git geçmişini şişirir).

Ölçümleri koşmadan önce buraya ORİJİNAL telefon fotoğrafı koy (2-5 MB;
WhatsApp'tan geçmiş veya ekran görüntüsü OLMAZ, ölçümü anlamsızlaştırır):

| Dosya          | İçerik                                              |
|----------------|-----------------------------------------------------|
| pantry_01.jpg  | buzdolabı üst raf: domates, salatalık, yumurta, süt, yoğurt |
| pantry_02.jpg  | tezgah üzeri: soğan, patates, havuç, yeşil biber     |
| dish_01.jpg    | kâse mercimek çorbası + ekmek (~300 g)              |
| dish_02.jpg    | tabakta tavuklu pilav (~350 g)                      |

Beklenen içerik `../ground_truth.json` dosyasında tanımlıdır.

Kullanan görevler:
- W4-T11 doğruluk ölçümü  -> python -m scripts.measure_vision_accuracy
- W4-T13 boyut ölçümü     -> python -m scripts.measure_api_performance