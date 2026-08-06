import 'package:flutter/material.dart'; //materşal design widgetlerini getirir: scaffold, card, chip, theme, icon, statedulWidget, State, BuildContext
///henüz yazılmamış ekranlar için geçici gövde
/// Icindeki sayac bilincli olarak eklendi: sekmeler arasi gecis yapip geri
/// donuldugunde sayacin SIFIRLANMAMASI, StatefulShellRoute'un her sekmenin
/// durumunu koruduğunun kanitidir (W1-T14 kabul kriteri).
class PlaceholderBody extends StatefulWidget { //Stateful Widget seçilmiş çünkü içinde değişen bir veri var o da _sayac eğer değişken veri olmasaydı StatelessEidget olurdu
  const PlaceholderBody({//constructor: flutter bu widget'i derleme zamanında sabitleyebilir; aynı parametrelerle çağrıldığında yeniden oluşmaz bu yüzden rebuil maliyeti düşer fakat const yapabilmek için tüm alanların final olması şart
    required this.title, //zorunlu verilmezse derleme hatası
    required this.icon, //zorunlu verilmezse derleme hatası
    this.subtitle,
    this.taskCode,
    this.actions = const [], //default olarak boş liste veriliyor, const[] olması önemli: her çağrıda yeni liste çağrılmaz
    super.key, //dart2-17+ süper parameter özelliği: flutterın widget ağacında elemanları eşleştirmesi için kullanılır
  });

  final String title; //hepsi final çünkü widget nesneleri immutable yani değişmez değişken şeyler State sınıfında tutulur
  final IconData icon; //ikon fontundaki kod noktasını temsil eder(Icons.add gibi): Icon widgetinin kendisi değil ham verisidir bu yüzden parametre olarak taşınması ucuz 
  final String? subtitle; //String? olduğu için default olarak null geliyor

  /// Bu ekranin hangi gorevde yazilacagi (or. 'W2-T06').
  final String? taskCode;

  /// Ekrandan gidilebilecek yerler.
  final List<({String label, IconData icon, VoidCallback onTap})> actions; //bu bir record(kayıt) tipi
  //süslü parantez içindekiler isimli alanlardır bu yüzden a.label a.icon a.onTap diye erişiyoruz eğer (String, IconDAta) gibi yazılsaydı a.+1 gibi erişebilinirdi
  //VoidCallback = void Function() için typedef parametresiz değer döndürmeyen fonksiyon

  @override
  State<PlaceholderBody> createState() => _PlaceholderBodyState();
  //flutter bu widfeti ağaca ilk yerleştirdiğinde bir kez çağırır ve donen State nesnesini saklar widget yeniden oluşturulsa bile State nesnesi aynı kalır: sayaçın korunmasınn teknik sebebi tam olarak budur ayrıca alt çizgi ile başladığı için sınıf dosyaya özel yani private
}

class _PlaceholderBodyState extends State<PlaceholderBody> {
  int _sayac = 0;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 72, color: tema.colorScheme.primary),
            const SizedBox(height: 16),
            Text(widget.title, style: tema.textTheme.headlineSmall),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium
                    ?.copyWith(color: tema.colorScheme.outline),
              ),
            ],
            if (widget.taskCode != null) ...[
              const SizedBox(height: 12),
              Chip(
                label: Text('${widget.taskCode} görevinde yazılacak'),
                visualDensity: VisualDensity.compact,
              ),
            ],
            const SizedBox(height: 32),

            // --- Durum korunuyor mu testi ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Durum testi', style: tema.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Sayacı artır, başka sekmeye geç, geri dön.\n'
                      'Değer korunuyorsa sekme durumu saklanıyor demektir.',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Text('$_sayac', style: tema.textTheme.displaySmall),
                    FilledButton.tonalIcon(
                      onPressed: () => setState(() => _sayac++),
                      icon: const Icon(Icons.add),
                      label: const Text('Artır'),
                    ),
                  ],
                ),
              ),
            ),

            if (widget.actions.isNotEmpty) ...[
              const SizedBox(height: 24),
              ...widget.actions.map(
                (a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: OutlinedButton.icon(
                    onPressed: a.onTap,
                    icon: Icon(a.icon),
                    label: Text(a.label),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}