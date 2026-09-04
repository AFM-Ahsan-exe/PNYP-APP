import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_user.dart';

class AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  DateTime? _lastVerificationSentAt;

  AuthRemoteDataSource(this._firebaseAuth, this._firestore);

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    // These used to be unconditional print() calls, logging emails, uids,
    // roles, and account status to the device log in every build
    // including release - real production-hygiene/info-exposure issue.
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('signInWithEmailAndPassword returned a null user');
    }
    final appUser = await _mapFirebaseUserWithProfile(firebaseUser);
    return appUser;
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

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('No authenticated user');
    // Rate limit: prevent spam - allow only once per 30 seconds
    if (_lastVerificationSentAt != null &&
        DateTime.now().difference(_lastVerificationSentAt!).inSeconds < 30) {
      throw firebase_auth.FirebaseAuthException(
        code: 'too-many-requests',
        message: 'Please wait before requesting another verification email.',
      );
    }
    await user.sendEmailVerification();
    _lastVerificationSentAt = DateTime.now();
  }

  Future<void> reloadCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('No authenticated user');
    await user.reload();
  }

  AppUser? getCurrentUser() {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return _mapFirebaseUser(
      firebaseUser,
      emailVerified: firebaseUser.emailVerified,
      roleName: 'member',
    );
  }

  Future<AppUser?> getCurrentUserWithRole() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    try {
      return await _mapFirebaseUserWithProfile(firebaseUser);
    } catch (_) {
      return _mapFirebaseUser(
        firebaseUser,
        emailVerified: firebaseUser.emailVerified,
        roleName: 'member',
      );
    }
  }

  Future<AppUser> _mapFirebaseUserWithProfile(firebase_auth.User user) async {
    final tokenResult = await user.getIdTokenResult(true);
    final isAdmin = tokenResult.claims?['admin'] == true;

    final profile = await _firestore.collection('users').doc(user.uid).get();
    final data = profile.data();
    final roleName = (data?['role'] as String?) ?? 'member';
    return _mapFirebaseUser(
      user,
      // Previously `isAdmin ? UserRole.admin : UserRole.fromString(roleName)`.
      // The `admin` boolean custom claim is granted to every coordinator
      // tier and above (district_coordinator through super_admin) - it's
      // a coarse "has admin-ish UI access" signal, not a role. Collapsing
      // everyone who has it down to the single UserRole.admin value threw
      // away their real role, which broke hasAtLeastRole() for every
      // genuine national_admin/president/super_admin: their role index
      // was always stuck at plain 'admin' (lower than national_admin),
      // so the client permanently believed they didn't qualify for
      // national-admin-gated screens (Audit Logs, System Settings) even
      // though the backend correctly recognized their real role. The
      // Firestore role field is the authoritative source and is already
      // kept in sync with custom claims by updateUserRole/approveMember,
      // so trusting it directly here is strictly more correct - and no
      // less secure, since every real authorization decision is enforced
      // server-side against the custom claim, never against this value.
      role: UserRole.fromString(roleName),
      status: isAdmin
          ? AccountStatus.approved
          : _parseStatus(data?['status'] as String?),
      roleName: roleName,
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
      emailVerified: user.emailVerified,
      onboardingCompleted: data?['onboardingCompleted'] as bool?,
      notificationPreferences: (data?['notificationPreferences'] as Map?)
          ?.cast<String, bool>(),
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
    String roleName = 'member',
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
    bool emailVerified = false,
    bool? onboardingCompleted,
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
      roleName: roleName,
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
      emailVerified: emailVerified,
      onboardingCompleted: onboardingCompleted,
      notificationPreferences: notificationPreferences,
      assignedProvince: assignedProvince,
      assignedDistrict: assignedDistrict,
    );
  }
}
