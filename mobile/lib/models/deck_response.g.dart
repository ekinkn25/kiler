// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeckResponse _$DeckResponseFromJson(Map<String, dynamic> json) =>
    _DeckResponse(
      sessionId: (json['session_id'] as num).toInt(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => RecipeCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      returned: (json['returned'] as num?)?.toInt() ?? 0,
      requested: (json['requested'] as num?)?.toInt() ?? 0,
      exhausted: json['exhausted'] as bool? ?? false,
      sessionFilters:
          json['session_filters'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$DeckResponseToJson(_DeckResponse instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'items': instance.items,
      'returned': instance.returned,
      'requested': instance.requested,
      'exhausted': instance.exhausted,
      'session_filters': instance.sessionFilters,
    };
