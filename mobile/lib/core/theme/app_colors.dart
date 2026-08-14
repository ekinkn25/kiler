import 'package:flutter/material.dart';

//semantik durum renkleri 

@immutable
class AppColors extends ThemeExtension<AppColors> {
  //eğer kendi özel renklerimizi flutterın ana tema sistemine yama yapmak(extend etmek) için ThemeExtension kullanırız
  const AppColors({
    required this.available,
    required this.missing,
    required this.unknown,
    required this.warning,
  });

  final Color available; 
  final Color missing;
  final Color unknown;
  final Color warning;

  static const AppColors standart = AppColors( //varsayılan standart değerler
    available: Color(0xFF2E7D32), 
    missing: Color(0xFFC62828), 
    unknown: Color(0xFF9E9E9E),
    warning: Color(0xFFF9A825),
  );

  @override
  AppColors copyWith({ //en üstte immutable yazdığı için bu classs yaratıldıktan sonra içindeki renkler doğrudan değiştirilemez fakat diyelim ki uygulamanın bir yerinde sadece missing rengini geçici olarak pembe yapmak istesen copyWith metodu ile mevcut renklerin tamamını kopyalar ve istediğmizi değiştirip bize objeler verir
    Color? available,
    Color? missing,
    Color? unknown,
    Color? warning,
  }) {
    return AppColors(
      available: available ?? this.available, 
      missing: missing ?? this.missing, 
      unknown: unknown ?? this.unknown, 
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t){
    //lerp: linear interpolation demek iki renk arasındaki geçişi hesaplar: kullanıcı açık temadan koyu temaya aldığında renkler şak diye aniden değişmesin 
    if (other is! AppColors) return this;
    return AppColors(
      available: Color.lerp(available, other.available, t) ?? available, 
      missing: Color.lerp(missing, other.missing, t) ?? missing, 
      unknown: Color.lerp(unknown, other.unknown, t) ?? unknown, 
      warning: Color.lerp(warning, other.warning, t) ?? warning, 
    );
  }
}

//eğer bunu yazmasaydık bir renk yazmak istediğimizde böyle yazacaktık Theme.of(context).extension<AppColors>()!.available fakat bu eklenti sayesinde arayüzde context.appColors.available bu şekilde yazabileceğiz
extension AppColorsContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>() ?? AppColors.standart;
}