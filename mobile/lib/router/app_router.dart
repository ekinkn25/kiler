import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/dev/dev_home_screen.dart';

//uygulamanın tüm yönlendirme tablosu burada 
//go router url tabanlı tek bir yerden okunabilir bir rota listesi sunar
//ekranlar birbirlerini doğrudan import etmez yalnızca rota adıyla geçiş yaparlar

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'dev-home',
        builder: (context, state) => const DevHomeScreen(),
      ),
    ],
  );
});