import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/network/cloud_functions_client.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final FirebaseAuth _auth;

  SearchRepositoryImpl(FirebaseFirestore _, this._auth);

  Future<Map<String, dynamic>> _callFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No authenticated user');
    final idToken = await user.getIdToken();
    final client = CloudFunctionsClient(
      projectId: Firebase.app().options.projectId,
      region: 'us-central1',
    );
    return client.call(functionName, data, idToken);
  }

  @override
  Future<List<SearchResult>> search(
    String query, {
    String? cursor,
    int limit = 20,
  }) async {
    final result = await _callFunction('searchContent', {
      'query': query,
      'cursor': cursor,
      'limit': limit,
    });
    final results = result['results'] as List<dynamic>? ?? [];
    return results
        .map((item) => SearchResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
