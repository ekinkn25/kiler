# Katkı ve Commit Kuralları

## Branch Stratejisi

| Branch | Amaç |
|---|---|
| `main` | Sadece çalışan, teslim edilebilir sürüm. Doğrudan push yapılmaz. |
| `develop` | Günlük geliştirme dalı. Varsayılan branch. |
| `feature/<görev-kodu>-<açıklama>` | Her atomik görev için ayrı dal. |
| `fix/<açıklama>` | Hata düzeltmeleri. |

**Akış:** `feature/*` → Pull Request → `develop` → hafta sonu → `main`

**Örnek dal isimleri:**
- `feature/w1-t02-python-venv`
- `feature/w2-t10-mlkit-barkod`
- `fix/kiler-birim-donusum-hatasi`

## Commit Formatı (Conventional Commits)

<tip>(<kapsam>): <açıklama>

### Tipler

| Tip | Ne zaman kullanılır | Örnek |
|---|---|---|
| `feat` | Yeni özellik | `feat(pantry): barkodla urun ekleme endpointi` |
| `fix` | Hata düzeltme | `fix(units): kg-gram donusumunde yuvarlama hatasi` |
| `docs` | Sadece dokümantasyon | `docs(readme): kurulum adimlari eklendi` |
| `style` | Biçim (mantık değişmedi) | `style(mobile): dart format uygulandi` |
| `refactor` | Davranış aynı, kod düzenlendi | `refactor(services): oneri skoru ayri module tasindi` |
| `test` | Test ekleme/düzenleme | `test(calories): BMR hesabi birim testleri` |
| `chore` | Bağımlılık, yapılandırma | `chore: alembic migration altyapisi kuruldu` |
| `perf` | Performans iyileştirmesi | `perf(db): canonical_name uzerine index eklendi` |

### Kapsamlar (scope)

`pantry` · `barcode` · `recipes` · `calories` · `shopping` · `chatbot` · `auth` · `db` · `mobile` · `backend`

### Kurallar

- Açıklama küçük harfle başlar, sonunda nokta yok
- **Türkçe karakter kullanma** (ı, ş, ğ, ü, ö, ç) — bazı terminal ve CI araçlarında bozuk görünür
- 72 karakteri geçme
- Her commit tek bir mantıksal değişikliği içersin

### Örnekler

feat(barcode): ML Kit ile cihaz uzerinde barkod okuma
fix(pantry): esik altina dusen urun listeye iki kez ekleniyordu
docs(architecture): mermaid sistem diyagrami eklendi
chore(mobile): riverpod ve dio bagimliliklari eklendi

## Gizli Bilgiler

- `.env` dosyası **asla** commit edilmez. Yeni bir değişken eklediğinde
  `.env.example` dosyasına **değeri olmadan** anahtarını ekle.
- API anahtarları (Groq, MongoDB) yalnızca backend tarafında bulunur.
  Mobil uygulamaya gömülmez — APK açılıp okunabilir.