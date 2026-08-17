// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: (json['id'] as num).toInt(),
  role: chatRoleFromJson(json['role'] as String),
  content: json['content'] as String,
  suggestedRecipeIds:
      (json['suggested_recipe_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  fromCache: json['from_cache'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': chatRoleToJson(instance.role),
      'content': instance.content,
      'suggested_recipe_ids': instance.suggestedRecipeIds,
      'from_cache': instance.fromCache,
      'created_at': instance.createdAt.toIso8601String(),
    };
