import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

void main(){
  runApp(const ProviderScope(child: KaloriApp()));
}

class KaloriApp extends ConsumerWidget{
  //normalde durum tutmayan sayfalar için stateless widget kullanırız ama riverpod ekledik ve riverpod benim providerlarımı okuyabilmesi için standart statelesswidgetin güçlendirilmiş bir versiyonuna ihtiyacı vardır bu da consumer widgettir, 
  //buil metodunun içine ref ekledik bu uygulamanın uzaktan kumandası gibi riverpod ile tanımlanan herhangi bir değişkene temaya ağ servisine doğrudan bu ref üzerinden ulaşabilirsin
  const KaloriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}