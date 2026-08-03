from fastapi import FastAPI

app = FastAPI(
    title="Kalori Sayaci API",
    description="Kiler yonetimi, kalori takibi ve yapay zeka tarif asistani",
    version="0.1.0",
)


@app.get("/health")
def health_check():
    """Ortamin ve sunucunun ayakta oldugunu dogrulayan basit kontrol."""
    return {"status": "ok", "service": "kalori-sayaci-api"}