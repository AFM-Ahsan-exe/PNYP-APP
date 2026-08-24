import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/offline/connectivity_wrapper.dart';
import '../core/errors/app_error_boundary.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return ConnectivityWrapper(
      isOnlineStream: Stream.value(true),
      isOnline: true,
      child: MaterialApp.router(
        title: 'PNYP Mobile Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) {
          return AppErrorBoundary(child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}