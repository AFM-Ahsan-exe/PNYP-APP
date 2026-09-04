import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'app/app.dart';
import 'core/services/notification_service.dart';
import 'features/notifications/presentation/providers/notification_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final notificationService = NotificationService();

  await _initializeServices(notificationService);

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(
          notificationService,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _initializeServices(NotificationService notificationService) async {
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
    );

    debugPrint('[APP] App Check activated');

    if (kDebugMode) {
      try {
        final token = await FirebaseAppCheck.instance.getToken();

        debugPrint('[APP] App Check debug token: $token');
        debugPrint(
          '[APP] Register this token in Firebase Console > '
          'App Check > Debug tokens',
        );
      } catch (e) {
        debugPrint('[APP] App Check debug token error: $e');
        debugPrint(
          '[APP] App will continue running in DEBUG mode. '
          'Register the debug token in Firebase Console.',
        );
      }
    }
  } catch (e) {
    debugPrint('[APP] App Check activation error: $e');
  }

  try {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    debugPrint('[APP] Analytics enabled');
  } catch (e) {
    debugPrint('[APP] Analytics initialization error: $e');
  }

  try {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    debugPrint('[APP] Crashlytics enabled');
  } catch (e) {
    debugPrint('[APP] Crashlytics initialization error: $e');
  }

  try {
    await notificationService.initialize();
    debugPrint('[APP] Notification service initialized');
  } catch (e) {
    debugPrint('[APP] Notification service initialization error: $e');
  }
}