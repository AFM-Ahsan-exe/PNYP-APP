import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/app_user.dart';

class CloudFunctionsClient {
  final String projectId;
  final String region;
  final String baseUrl;

  CloudFunctionsClient({
    required this.projectId,
    this.region = 'us-central1',
  }) : baseUrl = 'https://$region-$projectId.cloudfunctions.net';

  Future<Map<String, dynamic>> call(String functionName, Map<String, dynamic> data, String? idToken) async {
    final uri = Uri.parse('$baseUrl/$functionName');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (idToken != null) {
      headers['Authorization'] = 'Bearer $idToken';
    }
    final response = await http.post(uri, headers: headers, body: jsonEncode(data));
    if (response.statusCode != 200) {
      throw StateError(response.body);
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (result['error'] != null) {
      throw StateError(result['error']['message'] ?? 'Function call failed');
    }
    return result;
  }
}

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
