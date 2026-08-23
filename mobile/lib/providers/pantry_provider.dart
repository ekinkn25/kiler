import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/enums.dart';
import '../models/pantry_item.dart';

/// Kiler listesi (W3-T18).
///
/// autoDispose DEGIL: Kiler sekmesi ile Kesfet arasinda gidip gelmek
/// listeyi her seferinde yeniden cekmesin.
class PantryNotifier extends AsyncNotifier<List<PantryItem>> {
  @override
  Future<List<PantryItem>> build() => _cek();

  Future<List<PantryItem>> _cek() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get<List<dynamic>>('/pantry');
    return response.data!
        .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> yenile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_cek);
  }

  /// [Var] / [Bitti] hizli aksiyonu.
  ///
  /// Yanit listeyi YERINDE gunceller, yeniden CEKMEZ: tam liste
  /// yenilemesi ekrani bir an bosaltir ve kullanici hangi satira
  /// dokundugunu kaybeder.
  ///
  /// still_have=false -> kayit 'bitti' olur ve backend'in varsayilan
  /// listesinden duser; bu yuzden yerelde de listeden CIKARILIR.
  Future<void> durumDegistir(int itemId, {required bool stillHave}) async {
    final mevcut = state.valueOrNull;
    if (mevcut == null) return;

    final dio = ref.read(dioProvider);
    final response = await dio.patch<Map<String, dynamic>>(
      '/pantry/$itemId',
      data: {'still_have': stillHave},
    );
    final guncel = PantryItem.fromJson(response.data!);

    state = AsyncData(
      stillHave
          ? [for (final k in mevcut) if (k.id == itemId) guncel else k]
          : [for (final k in mevcut) if (k.id != itemId) k],
    );
  }
}

final pantryProvider =
    AsyncNotifierProvider<PantryNotifier, List<PantryItem>>(PantryNotifier.new);

/// Listeyi ekranin iki bolumune ayirir.
///
/// Backend `availability` alanini GUVEN SURESI UYGULANMIS olarak donuyor:
/// 7 gunu gecmis bir 'var' kaydi buraya 'bilinmiyor' olarak geliyor.
/// Yani istemci tarafinda ek bir tarih hesabi YAPILMIYOR.
final pantryGroupsProvider = Provider<({List<PantryItem> kesinVar, List<PantryItem> eminDegiliz})>((ref) {
  final liste = ref.watch(pantryProvider).valueOrNull ?? const <PantryItem>[];
  return (
    kesinVar: liste.where((k) => k.availability == Availability.available).toList(),
    eminDegiliz: liste.where((k) => k.availability == Availability.unknown).toList(),
  );
});