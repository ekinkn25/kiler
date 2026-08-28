import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/kilo_kaydi.dart';

void main() {
  test('backend yaniti cozulur', () {
    final kayit = KiloKaydi.fromJson({
      'id': 7,
      'logged_date': '2026-08-27',
      'weight_kg': 78.4,
    });

    expect(kayit.id, 7);
    expect(kayit.kiloKg, 78.4);
    expect(kayit.gun, DateTime(2026, 8, 27));
  });

  test('tarih saat dilimine gore KAYMAZ', () {
    // Saf tarih alani: 'Z' yok, toLocal() cagrilmiyor. Cagrilsaydi
    // UTC+3'te 27 Agustos'un 26 Agustos'a dusme riski olurdu.
    final kayit = KiloKaydi.fromJson({
      'id': 1,
      'logged_date': '2026-01-01',
      'weight_kg': 80,
    });

    expect(kayit.gun.day, 1);
    expect(kayit.gun.month, 1);
    expect(kayit.gun.year, 2026);
  });

  test('tam sayi gelen kilo double a cevrilir', () {
    // Backend 80.0 yerine 80 gonderebilir; num -> double donusumu
    // yapilmazsa '80 is not a double' ile patlardi.
    final kayit = KiloKaydi.fromJson({
      'id': 2,
      'logged_date': '2026-05-05',
      'weight_kg': 80,
    });

    expect(kayit.kiloKg, 80.0);
  });
}
