import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  member,
  districtCoordinator,
  regionalCoordinator,
  contentManager,
  opportunityManager,
  admin,
  nationalAdmin,
  president,
  superAdmin;

  static UserRole fromString(String role) {
    final normalized = role.replaceAll('_', '').toLowerCase();
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => UserRole.member,
    );
  }

  String get displayName {
    switch (this) {
      case UserRole.districtCoordinator:
        return 'District Coordinator';
      case UserRole.regionalCoordinator:
        return 'Regional Coordinator';
      case UserRole.contentManager:
        return 'Content Manager';
      case UserRole.opportunityManager:
        return 'Opportunity Manager';
      case UserRole.nationalAdmin:
        return 'National Admin';
      case UserRole.president:
        return 'President';
      case UserRole.superAdmin:
        return 'Super Admin';
      default:
        return name[0].toUpperCase() + name.substring(1);
    }
  }
}

enum AccountStatus { pending, approved, rejected, suspended, expired }

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final UserRole role;
  final AccountStatus status;
  final String roleName;
  final String? fullName;
  final String? fatherName;
  final Timestamp? dateOfBirth;
  final String? gender;
  final String? province;
  final String? district;
  final String? city;
  final String? phone;
  final String? education;
  final String? employment;
  final List<String> skills;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? referralSource;
  final String? membershipType;
  final String? membershipId;
  final Timestamp? membershipStartDate;
  final Timestamp? membershipExpiryDate;
  final String? profilePictureUrl;
  final String? cnicFrontUrl;
  final String? cnicBackUrl;
  final String? cvUrl;
  final String? paymentProofUrl;
  final String? fcmToken;
  final bool emailVerified;
  final bool? onboardingCompleted;
  final Map<String, bool>? notificationPreferences;
  final String? assignedProvince;
  final String? assignedDistrict;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.role = UserRole.member,
    this.status = AccountStatus.pending,
    this.roleName = 'member',
    this.fullName,
    this.fatherName,
    this.dateOfBirth,
    this.gender,
    this.province,
    this.district,
    this.city,
    this.phone,
    this.education,
    this.employment,
    this.skills = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.referralSource,
    this.membershipType,
    this.membershipId,
    this.membershipStartDate,
    this.membershipExpiryDate,
    this.profilePictureUrl,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.cvUrl,
    this.paymentProofUrl,
    this.fcmToken,
    this.emailVerified = false,
    this.onboardingCompleted,
    this.notificationPreferences,
    this.assignedProvince,
    this.assignedDistrict,
  });

  bool get isAdmin =>
      role == UserRole.admin ||
      role == UserRole.nationalAdmin ||
      role == UserRole.president ||
      role == UserRole.superAdmin;

  bool hasRole(String role) => roleName == role;

  bool hasAtLeastRole(String minimumRole) {
    const hierarchy = <UserRole>[
      UserRole.member,
      UserRole.districtCoordinator,
      UserRole.regionalCoordinator,
      UserRole.contentManager,
      UserRole.opportunityManager,
      UserRole.admin,
      UserRole.nationalAdmin,
      UserRole.president,
      UserRole.superAdmin,
    ];
    final callerIndex = hierarchy.indexOf(role);
    final requiredIndex = hierarchy.indexOf(UserRole.fromString(minimumRole));
    return callerIndex >= requiredIndex;
  }

  AppUser copyWith({
    String? displayName,
    UserRole? role,
    AccountStatus? status,
    String? roleName,
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
    List<String>? skills,
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
    bool? emailVerified,
    bool? onboardingCompleted,
    Map<String, bool>? notificationPreferences,
    String? assignedProvince,
    String? assignedDistrict,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      status: status ?? this.status,
      roleName: roleName ?? this.roleName,
      fullName: fullName ?? this.fullName,
      fatherName: fatherName ?? this.fatherName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      province: province ?? this.province,
      district: district ?? this.district,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      education: education ?? this.education,
      employment: employment ?? this.employment,
      skills: skills ?? this.skills,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      referralSource: referralSource ?? this.referralSource,
      membershipType: membershipType ?? this.membershipType,
      membershipId: membershipId ?? this.membershipId,
      membershipStartDate: membershipStartDate ?? this.membershipStartDate,
      membershipExpiryDate: membershipExpiryDate ?? this.membershipExpiryDate,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      cnicFrontUrl: cnicFrontUrl ?? this.cnicFrontUrl,
      cnicBackUrl: cnicBackUrl ?? this.cnicBackUrl,
      cvUrl: cvUrl ?? this.cvUrl,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      emailVerified: emailVerified ?? this.emailVerified,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      assignedProvince: assignedProvince ?? this.assignedProvince,
      assignedDistrict: assignedDistrict ?? this.assignedDistrict,
    );
  }
}
