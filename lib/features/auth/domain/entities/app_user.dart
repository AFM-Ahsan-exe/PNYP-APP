import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { member, admin }

enum AccountStatus { pending, approved, rejected, suspended, expired }

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final UserRole role;
  final AccountStatus status;
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
  final Map<String, bool>? notificationPreferences;
  final String? assignedProvince;
  final String? assignedDistrict;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.role = UserRole.member,
    this.status = AccountStatus.pending,
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
    this.notificationPreferences,
    this.assignedProvince,
    this.assignedDistrict,
  });

  bool get isAdmin => role == UserRole.admin;

  bool get emailVerified => false;

  AppUser copyWith({
    String? displayName,
    UserRole? role,
    AccountStatus? status,
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
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      assignedProvince: assignedProvince ?? this.assignedProvince,
      assignedDistrict: assignedDistrict ?? this.assignedDistrict,
    );
  }
}
