import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/lookup.dart';
import '../models/recipe_card.dart';

final dietTagsProvider = FutureProvider<List<DietTag>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get<List<dynamic>>('/catalog/diet-tags');
  return response.data!.map((e) => DietTag.fromJson(e as Map<String, dynamic>)).toList();
});

final allergensProvider = FutureProvider<List<Allergen>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get<List<dynamic>>('/catalog/allergens');
  return response.data!.map((e) => Allergen.fromJson(e as Map<String, dynamic>)).toList();
});

/// Adim 4'teki gorsel grid icin: swipe destesindeki ayni uc yeniden kullanilir.
final onboardingRecipeChoicesProvider = FutureProvider<List<RecipeCard>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get<Map<String, dynamic>>(
    '/recipes/deck',
    queryParameters: {'limit': 20},
  );
  final items = response.data!['items'] as List<dynamic>;
  return items.map((e) => RecipeCard.fromJson(e as Map<String, dynamic>)).toList();
});

/// Anket gonderimi. Basarili olursa authProvider'i yeniler ki
/// onboarding_completed=true'ya donmus kullanici her yerde gorunsun.
class OnboardingNotifier extends AsyncNotifier<double?> {
  @override
  Future<double?> build() async => null;

  Future<void> submit({
    int? birthYear,
    String? gender,
    double? heightCm,
    double? weightKg,
    required String activityLevel,
    required String goal,
    required int householdSize,
    required List<String> dietTagCodes,
    required List<String> allergenCodes,
    required List<String> likedRecipeIds,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      final response = await dio.post<Map<String, dynamic>>('/onboarding', data: {
        'profile': {
          'birth_year': birthYear,
          'gender': gender,
          'height_cm': heightCm,
          'weight_kg': weightKg,
          'activity_level': activityLevel,
          'goal': goal,
          'household_size': householdSize,
        },
        'diet_tag_codes': dietTagCodes,
        'allergen_codes': allergenCodes,
        'liked_recipe_ids': likedRecipeIds,
      });
      final profile = response.data!['profile'] as Map<String, dynamic>;
      return (profile['daily_calorie_target'] as num).toDouble();
    });
  }
}

final onboardingProvider = AsyncNotifierProvider<OnboardingNotifier, double?>(OnboardingNotifier.new);