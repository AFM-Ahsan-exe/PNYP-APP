enum UserRole { member, admin }

enum AccountStatus { pending, approved, rejected, suspended }

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final UserRole role;
  final AccountStatus status;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.role = UserRole.member,
    this.status = AccountStatus.pending,
  });

  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({
    String? displayName,
    UserRole? role,
    AccountStatus? status,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }
}
