import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 4 sekmeli alt navigasyonun govdesi.
///
/// [navigationShell] go_router'in StatefulShellRoute'u tarafindan
/// saglanir; hangi sekmenin aktif oldugunu ve sekmeler arasi gecisi
/// YONETIR. Bu widget SADECE gorunumu (NavigationBar) cizer, yonlendirme
/// mantigina KARISMAZ.
class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Sohbet',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Keşfet',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Kalori',
          ),
          NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen),
            label: 'Kiler',
          ),
        ],
      ),
    );
  }

  void _onDestinationSelected(int index) {
    // initialLocation: true -> aktif sekmeye TEKRAR basilirsa o sekmenin
    // kendi kok ekranina doner (derin gezinmisse sifirlanir). Cogu
    // uygulamada beklenen 'sekmeye tekrar bas = basa don' davranisi budur.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}