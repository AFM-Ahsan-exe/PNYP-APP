import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/offline/connectivity_wrapper.dart';
import '../core/errors/app_error_boundary.dart';
import '../features/notifications/presentation/providers/notification_providers.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  Stream<bool> _connectivityStream() async* {
    final connectivity = Connectivity();
    await for (final results in connectivity.onConnectivityChanged) {
      yield results.any((result) => result != ConnectivityResult.none);
    }
  }

  @override
  void initState() {
    super.initState();
    // Push notification taps (cold start or background) previously did
    // nothing beyond opening the app to whatever route the router
    // resolved normally - the target route captured by NotificationService
    // was never consumed. Listen for it here and navigate once the first
    // frame is up.
    final notificationService = ref.read(notificationServiceProvider);
    notificationService.pendingRouteStream.listen((route) {
      final router = ref.read(appRouterProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.push(route);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return ConnectivityWrapper(
      isOnlineStream: _connectivityStream(),
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
