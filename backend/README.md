# Backend — FastAPI

Python 3.11 + FastAPI + SQLAlchemy + Alembic.
SQLite (kullanıcı, kiler, kalori, alışveriş listesi) ve MongoDB (tarifler) ile çalışır.

## Klasör yapısı (W1-T03'te oluşturulacak)
app/
  core/      # config, security (JWT)
  db/        # session, base
  models/    # SQLAlchemy ORM modelleri
  schemas/   # Pydantic DTO'lar
  routers/   # API endpoint'leri
  services/  # iş mantığı (öneri motoru, LLM, birim dönüşümü)

## Çalıştırma
uvicorn app.main:app --reload

## Kurulum

python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env        # sonra SECRET_KEY'i doldur
uvicorn app.main:app --reload

SECRET_KEY uretmek icin:
python -c "import secrets; print(secrets.token_urlsafe(48))"