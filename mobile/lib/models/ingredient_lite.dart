class IngredientLite{
  const IngredientLite({
    required this.id,
    required this.canonicalName,
    required this.displayName,
  });

  factory IngredientLite.fromJson(Map<String, dynamic> json) => IngredientLite(
    canonicalName: json['canonical_name'] as String,
    id : json['id'] as int,
    displayName: json['display_name'] as String,
  );
  final int id;
  final String canonicalName;
  final String displayName;
}