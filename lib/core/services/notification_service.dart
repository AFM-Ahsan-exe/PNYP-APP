import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageStream;
  RemoteMessage? _initialMessage;

  // Push-notification taps (both cold start and background) previously set
  // _initialMessage but nothing ever read it to navigate anywhere -
  // tapping a notification just opened the app to whatever route the
  // router resolved normally. This stream lets app.dart react and
  // navigate to the notification's target route.
  final StreamController<String> _pendingRouteController =
      StreamController<String>.broadcast();
  Stream<String> get pendingRouteStream => _pendingRouteController.stream;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  RemoteMessage? get initialMessage => _initialMessage;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      _tokenSubscription = _messaging.onTokenRefresh.listen(_updateFcmToken);

      _messageStream = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _initialMessage = initialMessage;
        final route = initialMessage.data['actionRoute'] as String?;
        if (route != null) {
          _pendingRouteController.add(route);
        }
      }

      await _registerCurrentToken();

      _isInitialized = true;
    } catch (e) {
      debugPrint('FCM initialization failed: $e');
    }
  }

  Future<void> _registerCurrentToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final token = await _messaging.getToken();
      if (token == null) return;
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Non-blocking
    }
  }

  Future<void> _updateFcmToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FCM token update failed: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Foreground messages can be handled here if needed
    // Currently we rely on in-app notification inbox
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    _initialMessage = message;
    final route = message.data['actionRoute'] as String?;
    if (route != null) {
      _pendingRouteController.add(route);
    }
  }

  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      final user = _auth.currentUser;
      if (user == null) return;
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FCM token cleanup failed: $e');
    }
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _messageStream?.cancel();
    _tokenSubscription = null;
    _messageStream = null;
    _isInitialized = false;
  }
}
