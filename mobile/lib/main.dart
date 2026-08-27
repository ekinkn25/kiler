import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'core/hata/hata_kaydi.dart';
import 'widgets/hata_gorunumu.dart';

void main(){
  runZonedGuarded<void>(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        HataKaydi.yaz(details.exception, details.stack, kaynak: 'FlutterError');
        if (kDebugMode) FlutterError.presentError(details);
      };

      // true dondurmek 'hatayi ele aldim' demek; surec sonlandirilmaz.
      WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
        HataKaydi.yaz(error, stack, kaynak: 'PlatformDispatcher');
        return true;
      };

      ErrorWidget.builder = (details) => HataGorunumu(details: details);

      runApp(const ProviderScope(child: KaloriApp()));
    },
    (Object hata, StackTrace iz) {
      HataKaydi.yaz(hata, iz, kaynak: 'runZonedGuarded');
    },
  );
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