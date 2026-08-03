# 🥗 Kalori Sayacı + Akıllı Kiler Asistanı

Evdeki malzemeleri takip eden, barkod okuyarak kiler yöneten ve kalan günlük
kalorine göre yapay zeka ile yemek öneren mobil uygulama.

> Staj projesi — 20 iş günü MVP

## Problem

Piyasadaki uygulamalar ya **sadece kalori sayıyor** (MyFitnessPal, Yazio) ya da
**sadece tarif veriyor** (SuperCook, Yummly). Hiçbiri "elimde ne var, kalori
hedefimi aşmadan ne pişirebilirim?" sorusuna cevap vermiyor.

## Çekirdek Özellikler (MVP)

- 📦 **Kiler yönetimi** — barkod okutarak veya elle ürün ekleme, stok takibi
- 🔢 **Kalori sayacı** — BMR/TDEE tabanlı günlük hedef, öğün ve makro takibi
- 🍲 **Akıllı tarif önerisi** — kilerdeki malzeme + kalan kalori + diyet tercihi
- 💬 **Yapay zeka asistanı** — "Bugün hafif bir şey öner" → RAG ile gerçek tarif
- 🛒 **Otomatik alışveriş listesi** — eşik altına düşen ve eksik malzemeler
- 🟢🔴⚪ **Renkli malzeme kartları** — var / yok / veri yok

## Teknoloji Yığını

| Katman | Teknoloji |
|---|---|
| Mobil | Flutter, Dart, Material 3, Riverpod |
| Backend | Python, FastAPI, SQLAlchemy, Alembic |
| Veritabanı | SQLite (ilişkisel) + MongoDB Atlas (doküman) |
| Cihaz üstü AI | Google ML Kit (`mobile_scanner` ile barkod okuma) |
| Yapay zeka | Groq / LLaMA 3 + RAG mimarisi |
| Dış veri | Open Food Facts API |

## Klasör Yapısı

kalori-sayaci/
├── backend/   FastAPI servisi
├── mobile/    React Native uygulaması
├── docs/      Mimari ve ER diyagramları
└── data/      Tarif seed verisi, malzeme sözlüğü

## Kurulum

_(W4-T14'te doldurulacak)_

## Yol Haritası

- **V1 (MVP)** — barkod, kiler, kalori, tarif önerisi, chatbot
- **V2** — SKT bildirimleri, oyunlaştırma, offline mod, mağaza yayını
- **V3** — fiş OCR ile otomatik kiler kaydı, görsel obje tanıma

## Lisans

Özel — staj projesi.