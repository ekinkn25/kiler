import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/app_user.dart';

/// GET /auth/me sonucunu tutan AsyncNotifier.
///
/// Token yoksa veya gecersizse AuthInterceptor 401'i ApiException'a
/// cevirir; bu notifier hatayi oldugu gibi AsyncValue.error'a tasir.
class MeNotifier extends AsyncNotifier<AppUser> {
  @override
  Future<AppUser> build() => _fetch();

  Future<AppUser> _fetch() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get<Map<String, dynamic>>('/auth/me');
    return AppUser.fromJson(response.data!);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final meProvider = AsyncNotifierProvider<MeNotifier, AppUser>(MeNotifier.new);