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
    final user = await _mapFirebaseUserWithProfile(firebaseUser);
    await _firestore.collection('users').doc(firebaseUser.uid).set({
      'uid': firebaseUser.uid,
      'name': name.trim(),
      'email': (firebaseUser.email ?? email).toLowerCase(),
      'organizationId': organizationId,
      'role': 'member',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return user.copyWith(status: AccountStatus.pending);
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
  }) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      role: role,
      status: status,
    );
  }
}
