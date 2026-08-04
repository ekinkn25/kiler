"""Tüm sabit değer kümeleri tek dosyada. Bunlar hem DB'de CHECK kısıtına, hem Pydantic şemalarına dönüşecek.
Veritabanı ve API genelinde kullanılan sabit değer kümeleri
SQLite'ta native ENUM yoktur; bu sınıflarSQLAlchemy tarafından VHARCHAR + CHECK kısıtına çevirilir.
str'den miras alarak, SQLAlchemy'ye "Bunu veritabanına yazarken normal bir metin (string) gibi muamele et" diyoruz"""

import enum

#(str, enum.Enum) kullanımı Python'da Multiple Inheritance (Çoklu Kalıtım) veya String Enum (Mixin)
class Gender(str, enum.Enum):
    ERKEK = "erkek"
    KADIN = "kadin"
    BELIRTILMEDI = "belirtilmedi"

class ActivityLevel(str, enum.Enum):
    SEDANTER = "sedanter"
    HAFIF = "hafif"
    ORTA = "orta"
    YUKSEK = "yuksek"
    COK_YUKSEK = "cok_yuksek"

class Goal(str, enum.Enum): 
    KILO_VERME = "kilo_verme"
    KORUMA = "koruma"
    KILO_ALMA = "kilo_alma"

class UnitType(str, enum.Enum):
    """Temel birim tipi."""
    MASS = "mass"
    VOLUME = "volume"
    COUNT = "count"

class UnitCode(str, enum.Enum):
    G = "g"
    KG = "kg"
    ML = "ml"
    L = "l"
    ADET = "adet"
    PAKET = "paket"
    YEMEK_KASIGI = "yemek_kasigi"
    TATLI_KASIGI = "tatli_kasigi"
    CAY_KASIGI = "cay_kasigi"
    SU_BARDAGI = "su_bardagi"
    DEMET = "demet"
    DILIM = "dilim"

class ProductSource(str, enum.Enum):
    OPENFOODFACTS = "openfoodfacts"
    USER = "user"
    ADMIN = "admin"

class ShoppingSource(str, enum.Enum):
    MANUEL = "manuel"
    ESIK = "esik"
    TARIF = "tarif"
    ONGORU = "ongoru"

class MealType(str, enum.Enum):
    KAHVALTI = "kahvalti"
    OGLE = "ogle"
    AKSAM = "aksam"
    ATISTIRMA = "atistirma"

class LogSource(str, enum.Enum):
    MANUEL = "manuel"
    BARKOD = "barkod"
    TARIF = "tarif"

class FeedbackAction(str, enum.Enum):
    BEGENDIM = "begendim"
    BEGENMEDIM = "begenmedim"
    YAPTIM = "yaptim"
    ATLADIM = "atladim"

class TasteDimension(str, enum.Enum):
    CUISINE  = "cuisine"
    DIET_TAG = "diet_tag"
    INGREDIENT = "ingredient"
    DIFFICULTY = "difficulty"

class ChatRole(str, enum.Enum):
    USER = "user"
    ASSISTANT = "assistant"

class PantryEventType(str, enum.Enum):
    """Append-only kiler hareket gunlugunun olay tipleri."""
    EKLENDI = "eklendi"
    ARTTIRILDI = "arttirildi"
    TUKETILDI_TARIF = "tuketildi_tarif"
    TUKETILDI_MANUEL = "tuketildi_manuel"
    BOZULDU_ATILDI = "bozuldu_atildi"
    DUZELTME = "duzeltme"
    SILINDI = "silindi"