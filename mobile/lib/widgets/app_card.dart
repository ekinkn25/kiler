import 'package:flutter/material.dart';

//uygulamanın standart kart çerçevesi

class AppCard extends StatelessWidget{
  const AppCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(padding: padding, child: child);
    //dışarıdan gelen bu içeriği (child)ı al etrafına bizim standart paddinglerimizi ekle ve bu boşlık bırakılmış yei hali content adında bir değişkente paketle

    return Card(
      clipBehavior: Clip.antiAlias, //kartın kenarları yuvarlak içine kare resim koyarsak resmin sivri köşeleri kartın yucarlak sınırlarından dışarı taşmaması için clip yani kırpma yapar ayrıca antialias yani yumuşatma yapar bu kesim işlemini yaparken pikseller tırtıklı gözükmez kenarları yumuşatır
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: onTap == null //diyor ki tıklanabilen bi şey değil ise contenti göster sadece ama tıklanabiliyor ise contenti bi de inwkwell ile sarmala öyle göster
        ? content
        : InkWell( //ekranda görsel olarak hiç bir yer kaplamaz ancak içine koyduğun her şeye dokunma hissi ve material desin dalga (riple) efekti kazandırır bir çeşit animasyon buton basınca dokunduğun yerden dışarıya doğru yayılan grimsi su dalgası 
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: content,
          ),
        ),
    );
  }
}