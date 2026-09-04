import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ActivityLogger {
  ActivityLogger._();

  static Future<void> log({
    required String userId,
    required String action,
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;
      await firestore.collection('user_activity').add({
        'userId': userId,
        'action': action,
        'details': details ?? '',
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        if (user != null) 'userRole': 'authenticated',
      });
    } catch (e) {
      debugPrint('Activity logging failed: $e');
    }
  }

  static Future<void> logAdmin({
    required String title,
    required String type,
    String? subtitle,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;
      await firestore.collection('activity_logs').add({
        'title': title,
        'subtitle': subtitle,
        'type': type,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        if (user != null) 'userId': user.uid,
        if (user != null) 'userRole': user.displayName ?? 'unknown',
      });
    } catch (e) {
      debugPrint('Activity logging failed: $e');
    }
  }
}
