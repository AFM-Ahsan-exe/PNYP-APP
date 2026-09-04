import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/public_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../../core/network/cloud_functions_client.dart';
import 'package:firebase_core/firebase_core.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileRepositoryImpl(this._firestore, this._auth);

  Future<Map<String, dynamic>?> _callFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No authenticated user');
    final idToken = await user.getIdToken();
    final client = CloudFunctionsClient(
      projectId: Firebase.app().options.projectId,
      region: 'us-central1',
    );
    return client.call(functionName, data, idToken);
  }

  @override
  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final tokenResult = await user.getIdTokenResult(true);
    final isAdmin = tokenResult.claims?['admin'] == true;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    final roleName = (data['role'] as String?) ?? 'member';
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      // See auth_remote_datasource.dart's _mapFirebaseUserWithProfile for
      // why this no longer collapses to UserRole.admin based on the
      // coarse `admin` boolean claim.
      role: UserRole.fromString(roleName),
      status: isAdmin
          ? AccountStatus.approved
          : AccountStatus.values.firstWhere(
              (value) => value.name == data['status'],
              orElse: () => AccountStatus.pending,
            ),
      roleName: roleName,
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
      fcmToken: data['fcmToken'] as String?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      onboardingCompleted: data['onboardingCompleted'] as bool?,
      notificationPreferences: (data['notificationPreferences'] as Map?)
          ?.cast<String, bool>(),
      assignedProvince: data['assignedProvince'] as String?,
      assignedDistrict: data['assignedDistrict'] as String?,
    );
  }

  @override
Future<void> updateProfile(Map<String, dynamic> data) async {
  final user = _auth.currentUser;

  if (user == null) {
    throw StateError('No authenticated user');
  }

  const allowedFields = {
    'phone',
    'profilePictureUrl',
    'notificationPreferences',
    'onboardingCompleted',
    'education',
    'employment',
    'skills',
    'emergencyContactName',
    'emergencyContactPhone',
  };

  final sanitized = <String, dynamic>{};

  for (final entry in data.entries) {
    if (allowedFields.contains(entry.key)) {
      sanitized[entry.key] = entry.value;
    }
  }

  sanitized['updatedAt'] =
      FieldValue.serverTimestamp();

  await _firestore
      .collection('users')
      .doc(user.uid)
      .update(sanitized);
}

  @override
  Future<List<PublicProfile>> getMemberDirectory({String? query}) async {
    final result = await _callFunction('getMemberDirectory', {
      if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
    });
    final members = result?['members'] as List<dynamic>? ?? [];
    return members.map((m) {
      final data = m as Map<String, dynamic>;
      return PublicProfile(
        uid: data['id'] as String? ?? '',
        fullName: data['fullName'] as String?,
        province: data['province'] as String?,
        district: data['district'] as String?,
        city: data['city'] as String?,
        membershipType: data['membershipType'] as String?,
        membershipId: data['membershipId'] as String?,
        status: AccountStatus.values.firstWhere(
          (value) => value.name == data['status'],
          orElse: () => AccountStatus.pending,
        ),
        role: UserRole.fromString(data['role'] as String? ?? 'member'),
        profilePictureUrl: data['profilePictureUrl'] as String?,
      );
    }).toList();
  }
}
