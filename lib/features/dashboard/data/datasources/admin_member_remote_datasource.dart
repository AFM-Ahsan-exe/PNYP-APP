import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/admin_member.dart';

class AdminMemberRemoteDataSource {
  final FirebaseAuth _auth;
  final http.Client _client;
  final String baseUrl;

  AdminMemberRemoteDataSource(
    this._auth,
    this._client, {
    this.baseUrl = ApiConstants.baseUrl,
  });

  Future<Map<String, String>> _headers() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) throw StateError('You must be signed in as an admin');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<List<AdminMember>> getMembers({String status = 'pending'}) async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/admin/members?status=$status'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw StateError(response.body);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => AdminMember.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateStatus(String uid, String status, {String? reason}) async {
    final body = <String, dynamic>{'status': status};
    if (reason != null) body['reason'] = reason;
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/admin/members/$uid/status'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw StateError(response.body);
  }
}
