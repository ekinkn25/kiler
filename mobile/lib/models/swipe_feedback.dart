import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'swipe_feedback.freezed.dart';
part 'swipe_feedback.g.dart';

/// POST /recipes/{id}/swipe istek govdesi (backend: SwipeRequest).
///
/// DIKKAT: backend'de bu tam olarak 'SwipeFeedback' adiyla YOK - istek
/// SwipeRequest, yanit SwipeResponse. Gorev tanimindaki 'SwipeFeedback'
/// mobilin kart uzerinde URETTIGI geri bildirimi temsil ettigi icin
/// SwipeRequest'in alanlarini birebir tasir.
///
/// 'sevmedim' bir eylem DEGIL, sebeptir: kalici eleme icin
/// action=begenmedim + reason=sevmedim gonderilmeli.
@freezed
abstract class SwipeFeedback with _$SwipeFeedback {
  const factory SwipeFeedback({
    @JsonKey(fromJson: feedbackActionFromJson, toJson: feedbackActionToJson)
    required FeedbackAction action,
    @JsonKey(fromJson: _reasonOrNull, toJson: _reasonOrNullJson) FeedbackReason? reason,
    @JsonKey(name: 'session_id') int? sessionId,
    @JsonKey(name: 'missing_ingredient_id') int? missingIngredientId,
    int? rating,
    @JsonKey(name: 'servings_cooked') double? servingsCooked,
    String? comment,
  }) = _SwipeFeedback;

  factory SwipeFeedback.fromJson(Map<String, dynamic> json) =>
      _$SwipeFeedbackFromJson(json);
}

FeedbackReason? _reasonOrNull(String? value) =>
    value == null ? null : feedbackReasonFromJson(value);
String? _reasonOrNullJson(FeedbackReason? value) =>
    value == null ? null : feedbackReasonToJson(value);