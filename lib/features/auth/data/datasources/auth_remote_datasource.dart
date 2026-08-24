import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_user.dart';

class AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSource(this._firebaseAuth, this._firestore);

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('signInWithEmailAndPassword returned a null user');
    }
    return _mapFirebaseUserWithProfile(firebaseUser);
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required String organizationId,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('createUserWithEmailAndPassword returned a null user');
    }
    await firebaseUser.updateDisplayName(name.trim());
    return _mapFirebaseUserWithProfile(firebaseUser);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  AppUser? getCurrentUser() {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return _mapFirebaseUser(firebaseUser);
  }

  Future<AppUser?> getCurrentUserWithRole() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return _mapFirebaseUserWithProfile(firebaseUser);
  }

  Future<AppUser> _mapFirebaseUserWithProfile(firebase_auth.User user) async {
    final tokenResult = await user.getIdTokenResult(true);
    final isAdmin = tokenResult.claims?['admin'] == true;
    final profile = await _firestore.collection('users').doc(user.uid).get();
    final data = profile.data();
    return _mapFirebaseUser(
      user,
      role: isAdmin ? UserRole.admin : UserRole.member,
      status: isAdmin
          ? AccountStatus.approved
          : _parseStatus(data?['status'] as String?),
      fullName: data?['fullName'] as String?,
      fatherName: data?['fatherName'] as String?,
      dateOfBirth: data?['dateOfBirth'] as Timestamp?,
      gender: data?['gender'] as String?,
      province: data?['province'] as String?,
      district: data?['district'] as String?,
      city: data?['city'] as String?,
      phone: data?['phone'] as String?,
      education: data?['education'] as String?,
      employment: data?['employment'] as String?,
      skills: (data?['skills'] as List<dynamic>?)?.cast<String>() ?? const [],
      emergencyContactName: data?['emergencyContactName'] as String?,
      emergencyContactPhone: data?['emergencyContactPhone'] as String?,
      referralSource: data?['referralSource'] as String?,
      membershipType: data?['membershipType'] as String?,
      membershipId: data?['membershipId'] as String?,
      membershipStartDate: data?['membershipStartDate'] as Timestamp?,
      membershipExpiryDate: data?['membershipExpiryDate'] as Timestamp?,
      profilePictureUrl: data?['profilePictureUrl'] as String?,
      cnicFrontUrl: data?['cnicFrontUrl'] as String?,
      cnicBackUrl: data?['cnicBackUrl'] as String?,
      cvUrl: data?['cvUrl'] as String?,
      paymentProofUrl: data?['paymentProofUrl'] as String?,
      fcmToken: data?['fcmToken'] as String?,
      notificationPreferences: (data?['notificationPreferences'] as Map?)?.cast<String, bool>(),
      assignedProvince: data?['assignedProvince'] as String?,
      assignedDistrict: data?['assignedDistrict'] as String?,
    );
  }

  AccountStatus _parseStatus(String? value) {
    return AccountStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AccountStatus.pending,
    );
  }

  AppUser _mapFirebaseUser(
    firebase_auth.User user, {
    UserRole role = UserRole.member,
    AccountStatus status = AccountStatus.pending,
    String? fullName,
    String? fatherName,
    Timestamp? dateOfBirth,
    String? gender,
    String? province,
    String? district,
    String? city,
    String? phone,
    String? education,
    String? employment,
    List<String> skills = const [],
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? referralSource,
    String? membershipType,
    String? membershipId,
    Timestamp? membershipStartDate,
    Timestamp? membershipExpiryDate,
    String? profilePictureUrl,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? cvUrl,
    String? paymentProofUrl,
    String? fcmToken,
    Map<String, bool>? notificationPreferences,
    String? assignedProvince,
    String? assignedDistrict,
  }) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      role: role,
      status: status,
      fullName: fullName,
      fatherName: fatherName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      province: province,
      district: district,
      city: city,
      phone: phone,
      education: education,
      employment: employment,
      skills: skills,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      referralSource: referralSource,
      membershipType: membershipType,
      membershipId: membershipId,
      membershipStartDate: membershipStartDate,
      membershipExpiryDate: membershipExpiryDate,
      profilePictureUrl: profilePictureUrl,
      cnicFrontUrl: cnicFrontUrl,
      cnicBackUrl: cnicBackUrl,
      cvUrl: cvUrl,
      paymentProofUrl: paymentProofUrl,
      fcmToken: fcmToken,
      notificationPreferences: notificationPreferences,
      assignedProvince: assignedProvince,
      assignedDistrict: assignedDistrict,
    );
  }
}
