/// GET /recipes/cards yanitindaki tek kart (backend: RecipeCard - sade sema).
///
/// [IngredientLite] ile ayni gerekce: sohbet mini kartinda ve tarif detay
/// iskeletinde kullanilan kucuk bir DTO. freezed'e cevirmek build_runner
/// turu gerektirir, karsiliginda bir sey kazandirmaz.
///
/// DIKKAT: destedeki RecipeCard modeliyle KARISTIRMA - o, skorlanmis
/// ScoredRecipeCard'i yansitir ve final_score/score_breakdown zorunludur.
/// Bu uc onlari donmez.
class RecipeMini {
  const RecipeMini({
    required this.id,
    required this.title,
    required this.caloriesPerServing,
    this.imageUrl,
    this.prepTime = 0,
    this.cookTime = 0,
    this.difficulty = 'orta',
    this.dietTags = const [],
  });

  factory RecipeMini.fromJson(Map<String, dynamic> json) => RecipeMini(
    id: (json['id'] ?? json['_id']) as String,
    title: json['title'] as String,
    imageUrl: json['image_url'] as String?,
    caloriesPerServing: (json['calories_per_serving'] as num).toDouble(),
    prepTime: (json['prep_time'] as num?)?.toInt() ?? 0,
    cookTime: (json['cook_time'] as num?)?.toInt() ?? 0,
    difficulty: json['difficulty'] as String? ?? 'orta',
    dietTags:
        ((json['diet_tags'] as List<dynamic>?) ?? const []).cast<String>(),
  );

  final String id;
  final String title;
  final String? imageUrl;
  final double caloriesPerServing;
  final int prepTime;
  final int cookTime;
  final String difficulty;
  final List<String> dietTags;

  int get toplamSure => prepTime + cookTime;
}