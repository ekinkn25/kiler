import 'package:flutter/material.dart';

import '../models/app_user.dart';

/// Avatardaki bas harf.
///
/// TURKCE INCELIGI: Dart'in toUpperCase()'i dilden bagimsizdir ve
/// 'ismail' -> 'I' verir; dogrusu 'İ'. Tek karakterlik bir ayrinti ama
/// kullanicinin kendi adini yanlis gormesi demek.
String profilBasHarfi(String ad, String eposta) {
  final kaynak = ad.trim().isNotEmpty ? ad.trim() : eposta;
  if (kaynak.isEmpty) return '?';
  final ilk = kaynak[0];
  if (ilk == 'i') return 'İ';
  return ilk.toUpperCase();
}

/// '27 Ağustos 2026' bicimi.
///
/// NEDEN intl'in DateFormat'i DEGIL: Turkce ay adlari icin
/// initializeDateFormatting('tr') ve MaterialApp'e localizationsDelegates
/// gerekiyor; projede ikisi de yok. Tek bir tarih icin o kurulumu yapmak
/// yerine sabit liste yeterli. (Coklu dile gecilirse burasi devreder.)
const List<String> _aylar = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

String tarihMetni(DateTime t) => '${t.day} ${_aylar[t.month - 1]} ${t.year}';

/// Uyelik tarihi backend'den UTC gelir; kullaniciya KENDI saat diliminde
/// gosteriyoruz. Saf tarih alanlarinda (kilo gunlugu gibi) toLocal() YOK -
/// orada donusum tarihi bir gun kaydirabilir.
String uyelikTarihi(DateTime utc) => tarihMetni(utc.toLocal());

/// Yuvarlak bas harf avatari. Cekmecede kucuk, profil ekraninda buyuk.
class ProfilAvatar extends StatelessWidget {
  const ProfilAvatar({
    required this.ad,
    required this.eposta,
    this.yaricap = 28,
    super.key,
  });

  final String ad;
  final String eposta;
  final double yaricap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: yaricap,
      backgroundColor: renkler.primary,
      child: Text(
        profilBasHarfi(ad, eposta),
        style: TextStyle(
          // Yazi boyutu yaricapa oranli: ayni widget hem 28 hem 48'de
          // dogru gorunsun diye sabit deger vermiyoruz.
          fontSize: yaricap * 0.85,
          fontWeight: FontWeight.w600,
          color: renkler.onPrimary,
        ),
      ),
    );
  }
}

/// Tek olcu kutucugu (Boy / Kilo / Yas / BMI).
class OlcuKutusu extends StatelessWidget {
  const OlcuKutusu({
    required this.etiket,
    required this.deger,
    this.altMetin,
    super.key,
  });

  final String etiket;
  final String deger;
  final String? altMetin;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            deger,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            etiket,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: renkler.onSurfaceVariant),
          ),
          if (altMetin != null)
            Text(
              altMetin!,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: renkler.outline, fontSize: 10),
            ),
        ],
      ),
    );
  }
}

/// Diyet veya alerjen cipleri.
class CipGrubu extends StatelessWidget {
  const CipGrubu({
    required this.baslik,
    required this.etiketler,
    required this.renk,
    required this.yaziRengi,
    super.key,
  });

  final String baslik;
  final List<Etiket> etiketler;
  final Color renk;
  final Color yaziRengi;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          baslik,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        // Wrap: cip sayisi bilinmiyor, Row olsaydi tasardi.
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final e in etiketler)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: renk,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  e.displayName,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: yaziRengi),
                ),
              ),
          ],
        ),
      ],
    );
  }
}