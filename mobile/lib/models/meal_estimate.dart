/// POST /vision/meal yaniti (backend: MealEstimate).
///
/// Bu bir KAYIT DEGIL - kullanici onaylayana kadar oneri. Sade DTO,
/// RecipeMini gibi codegen'siz.
class MealEstimate {
  const MealEstimate({
    required this.dishName,
    required this.portion,
    required this.estimatedGrams,
    required this.imageHash,
    this.calories,
    this.proteinG,
    this.carbG,
    this.fatG,
    this.portionOptions = const [],
    this.scaleReferenceFound = false,
  });

  factory MealEstimate.fromJson(Map<String, dynamic> json) {
    final makro = json['macros'] as Map<String, dynamic>?;
    return MealEstimate(
      dishName: json['dish_name'] as String? ?? 'Bilinmeyen yemek',
      portion: json['portion'] as String? ?? 'orta',
      estimatedGrams: (json['estimated_grams'] as num?)?.toDouble() ?? 0,
      calories: (json['calories'] as num?)?.toDouble(),
      proteinG: (makro?['protein_g'] as num?)?.toDouble(),
      carbG: (makro?['carb_g'] as num?)?.toDouble(),
      fatG: (makro?['fat_g'] as num?)?.toDouble(),
      portionOptions:
          ((json['portion_options'] as List<dynamic>?) ?? const [])
              .map((e) => PortionOption.fromJson(e as Map<String, dynamic>))
              .toList(),
      scaleReferenceFound: json['scale_reference_found'] as bool? ?? false,
      imageHash: json['image_hash'] as String? ?? '',
    );
  }

  final String dishName;

  /// kucuk / orta / buyuk.
  final String portion;
  final double estimatedGrams;
  final double? calories;
  final double? proteinG;
  final double? carbG;
  final double? fatG;

  /// Porsiyon degistirilince YENIDEN ISTEK ATILMASIN diye backend her
  /// boy icin gram+kalori hazir donuyor.
  final List<PortionOption> portionOptions;

  /// Catal/kasik gibi bir olcek referansi bulundu mu (tahmin guvenilirligi).
  final bool scaleReferenceFound;

  final String imageHash;
}

/// Tek bir porsiyon secenegi.
class PortionOption {
  const PortionOption({
    required this.portion,
    required this.grams,
    this.calories,
  });

  factory PortionOption.fromJson(Map<String, dynamic> json) => PortionOption(
    portion: json['portion'] as String,
    grams: (json['grams'] as num).toDouble(),
    calories: (json['calories'] as num?)?.toDouble(),
  );

  final String portion;
  final double grams;
  final double? calories;
}