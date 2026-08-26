# Görme Modeli Doğruluk Ölçümü (W4-T11)

**Koşu:** `v1` &nbsp;|&nbsp; **Tarih:** 2026-08-25 &nbsp;|&nbsp; **Sağlayıcı:** `groq` &nbsp;|&nbsp; **Model:** `qwen/qwen3.6-27b`

Güven eşiği `VISION_MIN_CONFIDENCE=0.15`, madde tavanı `VISION_MAX_ITEMS=25`. Ölçüm üretim akışının kendisinden geçer.


## Tekrar üretme

```bash
cd backend && python -m scripts.measure_vision_accuracy --rapor ../docs/vision_accuracy.md
```

Model yanıtları `.vision_cache/` altında önbelleklenir; yeniden koşmak ücretsizdir. Prompt değişince önbellek anahtarı da değişir, o yüzden `--no-cache` gerekmez.
