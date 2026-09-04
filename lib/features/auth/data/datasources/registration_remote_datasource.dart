import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/network/cloud_functions_client.dart';
import '../../domain/entities/app_user.dart';

class RegistrationRemoteDataSource {
  final FirebaseAuth _auth;
  final CloudFunctionsClient _functionsClient;

  RegistrationRemoteDataSource(this._auth, this._functionsClient);

  Future<AppUser> submitRegistration({
    required Map<String, dynamic> data,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user');
    }

    final idToken = await user.getIdToken();
    await _functionsClient.call('submitRegistration', data, idToken);

    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: data['fullName'] as String?,
      role: UserRole.member,
      status: AccountStatus.pending,
    );
  }

  Future<String> uploadFile({
    required String path,
    required List<int> bytes,
    required String contentType,
  }) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);
    final uploadTask = ref.putData(Uint8List.fromList(bytes), metadata);
    final snapshot = await uploadTask;
    return snapshot.ref.fullPath;
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No authenticated user');
    await user.sendEmailVerification();
  }
}
