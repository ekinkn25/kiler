import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/shopping_item.dart';

void main() {
  test('sozlukle eslesen oge: ad ve kategori ingredient tan gelir', () {
    final oge = ShoppingItem.fromJson({
      'id': 1,
      'ingredient': {
        'id': 29,
        'canonical_name': 'domates',
        'display_name': 'Domates',
        'category': {'id': 4, 'code': 'manav', 'display_name': 'Manav'},
      },
      'custom_name': null,
      'is_checked': false,
      'source': 'tarif',
    });

    expect(oge.name, 'Domates');
    expect(oge.categoryName, 'Manav');
    expect(oge.ingredientId, 29);
    expect(oge.isChecked, isFalse);
  });

  test('serbest metin oge: ad custom_name, kategori null', () {
    final oge = ShoppingItem.fromJson({
      'id': 2,
      'ingredient': null,
      'custom_name': 'Özel bir şey',
      'is_checked': true,
      'source': 'manuel',
    });

    expect(oge.name, 'Özel bir şey');
    expect(oge.categoryName, isNull);
    expect(oge.ingredientId, isNull);
    expect(oge.isChecked, isTrue);
  });
}