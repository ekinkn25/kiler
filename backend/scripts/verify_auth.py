"""W1-T08 dogrulama: kayit -> giris -> korumali uc -> yenileme akisi.

Kullanim (backend/ klasorunde):  python -m scripts.verify_auth
Sunucuyu ayrica baslatmaya gerek yoktur.
DIKKAT: kalori.db uzerinde gercek bir test kullanicisi olusturur.
"""
import uuid

from fastapi.testclient import TestClient

from app.core.config import settings
from app.main import app

client = TestClient(app)
API = settings.API_V1_PREFIX

EMAIL = f"test_{uuid.uuid4().hex[:8]}@kalori-test.com"
PASSWORD = "GucluSifre123"

basarili = 0
basarisiz = 0


def kontrol(ad: str, kosul: bool, ek: str = "") -> None:
    global basarili, basarisiz
    if kosul:
        print(f"  [TAMAM] {ad}")
        basarili += 1
    else:
        print(f"  [HATA ] {ad} {ek}")
        basarisiz += 1


print("\n1) Kayit")
r = client.post(f"{API}/auth/register", json={"email": EMAIL, "password": PASSWORD, "full_name": "Test Kullanici"})
kontrol("POST /auth/register -> 201", r.status_code == 201, f"(gelen: {r.status_code} {r.text[:200]})")
kontrol("Yanitta id var", "id" in r.json() if r.status_code == 201 else False)
kontrol("Yanitta hashed_password YOK", "hashed_password" not in r.text)
kontrol("E-posta kucuk harfe normalize", r.json().get("email") == EMAIL.lower() if r.status_code == 201 else False)

print("\n2) Mukerrer kayit reddediliyor mu?")
r = client.post(f"{API}/auth/register", json={"email": EMAIL, "password": PASSWORD})
kontrol("Ayni e-posta -> 409", r.status_code == 409, f"(gelen: {r.status_code})")
kontrol("Hata formati {code, message}", r.json().get("code") == "conflict")

print("\n3) Giris")
r = client.post(f"{API}/auth/login", json={"email": EMAIL, "password": PASSWORD})
kontrol("POST /auth/login -> 200", r.status_code == 200, f"(gelen: {r.status_code} {r.text[:200]})")
tokens = r.json() if r.status_code == 200 else {}
access = tokens.get("access_token", "")
refresh_token = tokens.get("refresh_token", "")
kontrol("access_token dondu", bool(access))
kontrol("refresh_token dondu", bool(refresh_token))

r = client.post(f"{API}/auth/login", json={"email": EMAIL, "password": "YanlisSifre123"})
kontrol("Yanlis sifre -> 401", r.status_code == 401, f"(gelen: {r.status_code})")
kontrol("Mesaj hangi alanin yanlis oldugunu SOYLEMIYOR",
        "sifre hatali" in r.json().get("message", "").lower())

print("\n4) Korumali uc")
r = client.get(f"{API}/auth/me")
kontrol("Token'siz istek -> 401", r.status_code == 401, f"(gelen: {r.status_code})")
kontrol("WWW-Authenticate basligi var", "www-authenticate" in {k.lower() for k in r.headers})

r = client.get(f"{API}/auth/me", headers={"Authorization": "Bearer sacma-sapan-token"})
kontrol("Gecersiz token -> 401", r.status_code == 401, f"(gelen: {r.status_code})")

r = client.get(f"{API}/auth/me", headers={"Authorization": f"Bearer {access}"})
kontrol("Gecerli token -> 200", r.status_code == 200, f"(gelen: {r.status_code} {r.text[:200]})")
kontrol("Dogru kullanici dondu", r.json().get("email") == EMAIL.lower() if r.status_code == 200 else False)
kontrol("Yanitta hashed_password YOK", "hashed_password" not in r.text)

print("\n5) Token tipi kontrolu")
r = client.get(f"{API}/auth/me", headers={"Authorization": f"Bearer {refresh_token}"})
kontrol("Refresh token ile korumali uca ERISILEMIYOR -> 401", r.status_code == 401,
        f"(gelen: {r.status_code} -- GUVENLIK ACIGI!)")

print("\n6) Token yenileme")
r = client.post(f"{API}/auth/refresh", json={"refresh_token": refresh_token})
kontrol("POST /auth/refresh -> 200", r.status_code == 200, f"(gelen: {r.status_code})")
yeni_access = r.json().get("access_token", "") if r.status_code == 200 else ""
kontrol("Yeni access_token dondu", bool(yeni_access))

r = client.get(f"{API}/auth/me", headers={"Authorization": f"Bearer {yeni_access}"})
kontrol("Yeni token calisiyor -> 200", r.status_code == 200)

r = client.post(f"{API}/auth/refresh", json={"refresh_token": access})
kontrol("Access token ile refresh YAPILAMIYOR -> 401", r.status_code == 401,
        f"(gelen: {r.status_code} -- GUVENLIK ACIGI!)")

print("\n7) Swagger form girisi")
r = client.post(f"{API}/auth/token", data={"username": EMAIL, "password": PASSWORD})
kontrol("POST /auth/token (form) -> 200", r.status_code == 200, f"(gelen: {r.status_code})")

print(f"\n{'-' * 55}")
print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")
print(f"Olusturulan test kullanicisi: {EMAIL}")