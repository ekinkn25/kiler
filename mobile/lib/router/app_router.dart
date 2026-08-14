import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/dev/dev_home_screen.dart';
import '../screens/dev/widget_showcase_screen.dart';
import 'package:flutter/material.dart';
import '../screens/main_shell.dart';
import '../screens/placeholder_screen.dart';


//uygulamanın tüm yönlendirme tablosu burada 
//go router url tabanlı tek bir yerden okunabilir bir rota listesi sunar
//ekranlar birbirlerini doğrudan import etmez yalnızca rota adıyla geçiş yaparlar

final _sohbetKey = GlobalKey<NavigatorState>(debugLabel: 'sohbet');
final _kesfetKey = GlobalKey<NavigatorState>(debugLabel: 'kesfet');
final _kaloriKey = GlobalKey<NavigatorState>(debugLabel: 'kalori');
final _kilerKey = GlobalKey<NavigatorState>(debugLabel: 'kiler');

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/sohbet',
    // NOT: Giris/onboarding yonlendirmesi (redirect:) HENUZ YOK - kimlik
    // dogrulama mobil gorevinde eklenecek. Simdilik dogrudan sekmelere
    // giriyoruz; bu W2-T15'in kapsami disinda BILEREK birakildi.
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _sohbetKey,
            routes: [
              GoRoute(
                path: '/sohbet',
                name: 'sohbet',
                builder: (context, state) => const PlaceholderScreen(title: 'Sohbet'),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _kesfetKey,
            routes: [
              GoRoute(
                path: '/kesfet',
                name: 'kesfet',
                builder: (context, state) => const PlaceholderScreen(title: 'Keşfet'),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _kaloriKey,
            routes: [
              GoRoute(
                path: '/kalori',
                name: 'kalori-tab',
                builder: (context, state) => const PlaceholderScreen(title: 'Kalori'),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _kilerKey,
            routes: [
              GoRoute(
                path: '/kiler',
                name: 'kiler',
                builder: (context, state) => const PlaceholderScreen(title: 'Kiler'),
              ),
            ],
          ),
        ],
      ),

      // ---------------------------------------------------------------
      // KABUK DISI tam ekran rotalar: alt navigasyon cubugu GORUNMEZ,
      // kok Navigator'a PUSH edilir - altta sekme yigini KORUNUR.
      // ---------------------------------------------------------------
      GoRoute(
        path: '/tara',
        name: 'tara',
        builder: (context, state) => const PlaceholderScreen(title: 'Barkod Tara'),
      ),
      GoRoute(
        path: '/tarif/:id',
        name: 'tarif-detay',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PlaceholderScreen(title: 'Tarif Detayı', detail: 'id: $id');
        },
      ),
      GoRoute(
        path: '/alisveris',
        name: 'alisveris',
        builder: (context, state) => const PlaceholderScreen(title: 'Alışveriş Listesi'),
      ),
      GoRoute(
        path: '/profil',
        name: 'profil',
        builder: (context, state) => const PlaceholderScreen(title: 'Profil'),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const PlaceholderScreen(title: 'Onboarding'),
      ),
      GoRoute(
        path: '/giris',
        name: 'giris',
        builder: (context, state) => const PlaceholderScreen(title: 'Giriş'),
      ),

      // ---------------------------------------------------------------
      // GECICI gelistirme rotalari (W2-T13/T14). '/' yerine artik '/dev'
      // altindalar; sekmeler devreye girdikten sonra dogrudan erisim
      // butonu yok - web'de adres cubugundan veya derin baglanti testiyle
      // (bkz. calistirma adimlari) acilabilir.
      // ---------------------------------------------------------------
      GoRoute(
        path: '/dev',
        name: 'dev-home',
        builder: (context, state) => const DevHomeScreen(),
      ),
      GoRoute(
        path: '/dev/widgets',
        name: 'widget-showcase',
        builder: (context, state) => const WidgetShowcaseScreen(),
      ),
    ],
  );
});