import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/enums.dart';
import 'package:kalori/models/pantry_item.dart';

void main() {
  test("PantryItem.fromJson 'var' degerini Availability.available'a cevirir", () {
    final json = {
      'id': 12,
      'ingredient': {
        'id': 29,
        'canonical_name': 'domates',
        'display_name': 'Domates',
        'calories_per_100g': 18.0,
        'is_staple': true,
      },
      'product': null,
      'availability': 'var',
      'source': 'barkod',
      'confirmed_at': '2026-08-13T12:28:00Z',
      'confidence_expires_at': '2026-08-20T12:28:00Z',
      'days_remaining': 6,
      'detected_confidence': null,
      'quantity_base': null,
      'display_unit': null,
      'expiry_date': null,
      'is_active': true,
      'created_at': '2026-08-13T12:28:00Z',
      'updated_at': '2026-08-13T12:28:00Z',
      'is_low': false,
      'display_quantity': 0.0,
    };

    final item = PantryItem.fromJson(json);

    expect(item.availability, Availability.available);
    expect(item.source, PantrySource.barkod);
    expect(item.ingredient.canonicalName, 'domates');
    expect(item.product, isNull);
    expect(item.daysRemaining, 6);
  });
}