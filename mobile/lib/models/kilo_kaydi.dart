/// GET /me/weight yanitindaki tek kayit (backend: WeightLogRead).
///
/// NEDEN freezed DEGIL: uc alani var, kopyalanmiyor, karsilastirilmiyor.
/// Bir DTO icin uc uretilmis dosya (freezed + g.dart) tasimak zorunda
/// degiliz - shopping_item.dart ile ayni tercih.
class KiloKaydi {
  const KiloKaydi({
    required this.id,
    required this.gun,
    required this.kiloKg,
  });

  factory KiloKaydi.fromJson(Map<String, dynamic> json) => KiloKaydi(
    id: json['id'] as int,
    // Backend 'YYYY-MM-DD' doner (date, datetime DEGIL): saat dilimi
    // donusumu YAPILMAZ. toLocal() cagrilsaydi kullanicinin diliminde
    // tarih bir gun kayabilirdi.
    gun: DateTime.parse(json['logged_date'] as String),
    kiloKg: (json['weight_kg'] as num).toDouble(),
  );

  final int id;
  final DateTime gun;
  final double kiloKg;
}
