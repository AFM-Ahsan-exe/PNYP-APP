import '../../../auth/domain/entities/app_user.dart';

class PublicProfile {
  final String uid;
  final String? fullName;
  final String? province;
  final String? district;
  final String? city;
  final String? membershipType;
  final String? membershipId;
  final AccountStatus status;
  final UserRole role;
  final String? profilePictureUrl;

  const PublicProfile({
    required this.uid,
    this.fullName,
    this.province,
    this.district,
    this.city,
    this.membershipType,
    this.membershipId,
    required this.status,
    required this.role,
    this.profilePictureUrl,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    return PublicProfile(
      uid: json['uid'] as String? ?? '',
      fullName: json['fullName'] as String?,
      province: json['province'] as String?,
      district: json['district'] as String?,
      city: json['city'] as String?,
      membershipType: json['membershipType'] as String?,
      membershipId: json['membershipId'] as String?,
      status: AccountStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => AccountStatus.pending,
      ),
      role: UserRole.fromString(json['role'] as String? ?? 'member'),
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'province': province,
      'district': district,
      'city': city,
      'membershipType': membershipType,
      'membershipId': membershipId,
      'status': status.name,
      'role': role.name,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}
