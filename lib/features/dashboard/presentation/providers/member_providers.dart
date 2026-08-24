import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/app_user.dart';

final memberUserProvider = FutureProvider<AppUser?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  if (!doc.exists) return null;
  final data = doc.data()!;
  return AppUser(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    fullName: data['fullName'] as String?,
    fatherName: data['fatherName'] as String?,
    dateOfBirth: data['dateOfBirth'] as Timestamp?,
    gender: data['gender'] as String?,
    province: data['province'] as String?,
    district: data['district'] as String?,
    city: data['city'] as String?,
    phone: data['phone'] as String?,
    education: data['education'] as String?,
    employment: data['employment'] as String?,
    skills: (data['skills'] as List<dynamic>?)?.cast<String>() ?? const [],
    emergencyContactName: data['emergencyContactName'] as String?,
    emergencyContactPhone: data['emergencyContactPhone'] as String?,
    membershipType: data['membershipType'] as String?,
    membershipId: data['membershipId'] as String?,
    membershipStartDate: data['membershipStartDate'] as Timestamp?,
    membershipExpiryDate: data['membershipExpiryDate'] as Timestamp?,
    profilePictureUrl: data['profilePictureUrl'] as String?,
    cnicFrontUrl: data['cnicFrontUrl'] as String?,
    cnicBackUrl: data['cnicBackUrl'] as String?,
    cvUrl: data['cvUrl'] as String?,
    paymentProofUrl: data['paymentProofUrl'] as String?,
    notificationPreferences: (data['notificationPreferences'] as Map?)?.cast<String, bool>(),
  );
});
