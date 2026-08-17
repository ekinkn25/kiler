import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// Sohbet gecmisindeki tek mesaj (backend: ChatMessageRead).
@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required int id,
    @JsonKey(fromJson: chatRoleFromJson, toJson: chatRoleToJson)
    required ChatRole role,
    required String content,
    @JsonKey(name: 'suggested_recipe_ids') @Default([]) List<String> suggestedRecipeIds,
    @JsonKey(name: 'from_cache') @Default(false) bool fromCache,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}