import '../../../auth/domain/entities/app_user.dart';

class AdminMember {
  final String uid;
  final String name;
  final String email;
  final AccountStatus status;
  final UserRole role;

  const AdminMember({
    required this.uid,
    required this.name,
    required this.email,
    required this.status,
    required this.role,
  });

  factory AdminMember.fromJson(Map<String, dynamic> json) {
    return AdminMember(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: AccountStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => AccountStatus.pending,
      ),
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.member,
    );
  }
}
