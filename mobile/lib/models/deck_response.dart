import 'package:freezed_annotation/freezed_annotation.dart';

import 'recipe_card.dart';

part 'deck_response.freezed.dart';
part 'deck_response.g.dart';

/// GET /recipes/deck yaniti (backend: DeckResponse).
@freezed
abstract class DeckResponse with _$DeckResponse {
  const factory DeckResponse({
    @JsonKey(name: 'session_id') required int sessionId,
    @Default([]) List<RecipeCard> items,
    @Default(0) int returned,
    @Default(0) int requested,
    @Default(false) bool exhausted,
    @JsonKey(name: 'session_filters') @Default({}) Map<String, dynamic> sessionFilters,
  }) = _DeckResponse;

  factory DeckResponse.fromJson(Map<String, dynamic> json) => _$DeckResponseFromJson(json);
}