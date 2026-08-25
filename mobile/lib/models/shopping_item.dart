/// GET /shopping yanitindaki tek oge (backend: ShoppingItemRead).
///
/// Sade DTO: kategoriye gore gruplama, isaretleme ve kilere aktarma icin
/// ekranin ihtiyac duydugu alanlar. ingredientId null ise (sozlukte
/// eslesmeyen serbest metin) kilere aktarilamaz.
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.isChecked,
    required this.source,
    this.canonicalName,
    this.categoryName,
    this.ingredientId,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    final ing = json['ingredient'] as Map<String, dynamic>?;
    final cat = ing?['category'] as Map<String, dynamic>?;
    return ShoppingItem(
      id: json['id'] as int,
      name: (ing?['display_name'] as String?) ??
          (json['custom_name'] as String?) ??
          '—',
      canonicalName: ing?['canonical_name'] as String?,
      categoryName: cat?['display_name'] as String?,
      isChecked: json['is_checked'] as bool? ?? false,
      source: json['source'] as String? ?? 'manuel',
      ingredientId: ing?['id'] as int?,
    );
  }

  final int id;
  final String name;
  final String? canonicalName;
  final String? categoryName;
  final bool isChecked;

  /// tarif / manuel / esik / ongoru
  final String source;

  /// Sozlukte eslesmeyen serbest metinlerde null.
  final int? ingredientId;
}