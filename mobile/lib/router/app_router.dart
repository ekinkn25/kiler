import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/dev/dev_home_screen.dart';
import '../screens/dev/widget_showcase_screen.dart';
import 'package:flutter/material.dart';
import '../screens/main_shell.dart';
import '../screens/placeholder_screen.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/discover/discover_screen.dart';
import '../screens/dev/dev_swipe_preview_screen.dart';


//uygulamanın tüm yönlendirme tablosu burada 
//go router url tabanlı tek bir yerden okunabilir bir rota listesi sunar
//ekranlar birbirlerini doğrudan import etmez yalnızca rota adıyla geçiş yaparlar

final _sohbetKey = GlobalKey<NavigatorState>(debugLabel: 'sohbet');
final _kesfetKey = GlobalKey<NavigatorState>(debugLabel: 'kesfet');
final _kaloriKey = GlobalKey<NavigatorState>(debugLabel: 'kalori');
final _kilerKey = GlobalKey<NavigatorState>(debugLabel: 'kiler');


class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    _sub = ref.listen(authProvider, (previous, next) => notifyListeners());
  }

  late final ProviderSubscription<AsyncValue<AppUser?>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthRefreshListenable(ref);
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: '/splash',  //dev/swipe',
    refreshListenable: authListenable,

    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final hedef = state.matchedLocation;
      final splashaGidiyor = hedef == '/splash';
      final authEkraniMi = hedef == '/giris' || hedef == '/kayit';
      // final devRotasiMi = hedef == '/dev' || hedef == '/dev/widgets';
      final devRotasiMi = hedef.startsWith('/dev');
      if (devRotasiMi) return null;

      final ilkAcilisKontrolEdiliyor =
          authState.isLoading && !authState.hasValue && !authState.hasError;
      if (ilkAcilisKontrolEdiliyor) {
        return splashaGidiyor ? null : '/splash';
      }

      final girisYapilmis = authState.valueOrNull != null;

      if (!girisYapilmis) {
        return authEkraniMi ? null : '/giris';
      }

      if (splashaGidiyor || authEkraniMi) {
        return '/sohbet';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/giris',
        name: 'giris',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/kayit',
        name: 'kayit',
        builder: (context, state) => const RegisterScreen(),
      ),
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
                builder: (context, state) => const DiscoverScreen(),
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
      // KABUK DISI tam ekran rotalar.
      // ---------------------------------------------------------------
      GoRoute(
        path: '/tara',
        name: 'tara',
        builder: (context, state) => const PlaceholderScreen(title: 'Barkod Tara'),
      ),
      GoRoute(
        path: '/foto',
        name: 'foto',
        builder: (context, state) => const PlaceholderScreen(title: 'Fotoğraf Çek'),
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
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ---------------------------------------------------------------
      // GECICI gelistirme rotalari.
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
      GoRoute(
        path: '/dev/swipe',
        name: 'dev-swipe',
        builder: (context, state) => const DevSwipePreviewScreen(),
      ),
    ],
  );
});