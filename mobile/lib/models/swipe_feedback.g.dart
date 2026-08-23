// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SwipeFeedback _$SwipeFeedbackFromJson(Map<String, dynamic> json) =>
    _SwipeFeedback(
      action: feedbackActionFromJson(json['action'] as String),
      reason: _reasonOrNull(json['reason'] as String?),
      sessionId: (json['session_id'] as num?)?.toInt(),
      missingIngredientId: (json['missing_ingredient_id'] as num?)?.toInt(),
      missingIngredientIds:
          (json['missing_ingredient_ids'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      rating: (json['rating'] as num?)?.toInt(),
      servingsCooked: (json['servings_cooked'] as num?)?.toDouble(),
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$SwipeFeedbackToJson(_SwipeFeedback instance) =>
    <String, dynamic>{
      'action': feedbackActionToJson(instance.action),
      'reason': _reasonOrNullJson(instance.reason),
      'session_id': instance.sessionId,
      'missing_ingredient_id': instance.missingIngredientId,
      'missing_ingredient_ids': instance.missingIngredientIds,
      'rating': instance.rating,
      'servings_cooked': instance.servingsCooked,
      'comment': instance.comment,
    };
