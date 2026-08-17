import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/chat_message.dart';
import 'package:kalori/models/enums.dart';

void main() {
  test('ChatMessage.fromJson role enumunu dogru cevirir', () {
    final json = {
      'id': 3,
      'role': 'assistant',
      'content': '3 tarif buldum, umarim begenirsin!',
      'suggested_recipe_ids': ['6a732db3dfd2dca131c56923'],
      'from_cache': false,
      'created_at': '2026-08-13T15:28:00Z',
    };

    final mesaj = ChatMessage.fromJson(json);

    expect(mesaj.role, ChatRole.assistant);
    expect(mesaj.suggestedRecipeIds, hasLength(1));
    expect(mesaj.fromCache, isFalse);
  });
}