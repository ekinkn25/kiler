class IngredientLite{
  const IngredientLite({
    required this.id,
    required this.canonicalName,
    required this.displayName,
    this.caloriesPer100g,
    this.unitType,
    this.gramsPerPiece,
  });

  factory IngredientLite.fromJson(Map<String, dynamic> json) => IngredientLite(
    canonicalName: json['canonical_name'] as String,
    id : json['id'] as int,
    displayName: json['display_name'] as String,
    caloriesPer100g: (json['calories_per_100g'] as num?)?.toDouble(),
    unitType: json['default_unit_type'] as String?,
    gramsPerPiece: (json['grams_per_piece'] as num?)?.toDouble(),
  );
  final int id;
  final String canonicalName;
  final String displayName;
  final double? caloriesPer100g;

  /// 'mass' | 'volume' | 'count'
  final String? unitType;
  final double? gramsPerPiece;

  /// Adet ile eklenebilir mi (elma, yumurta gibi).
  bool get adetSecilebilir => unitType == 'count' && gramsPerPiece != null;
}