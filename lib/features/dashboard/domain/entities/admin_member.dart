import '../../../auth/domain/entities/app_user.dart';

class AdminMember {
  final String uid;
  final String name;
  final String email;
  final AccountStatus status;
  final String role;

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
      // The Firestore user document field is `fullName` (see
      // functions/src/auth.ts#submitRegistration) - this read `name`,
      // a key that never exists on the document, so every member's
      // name was silently always empty ("Unnamed member" for
      // everyone), and searching by name could never match anything
      // no matter what was typed.
      name: json['fullName'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: AccountStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => AccountStatus.pending,
      ),
      role: json['role'] as String? ?? 'member',
    );
  }
}
