import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/usecases/search_content.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(
    ref.watch(firestoreProvider),
    FirebaseAuth.instance,
  );
});

final searchContentProvider = Provider<SearchContent>((ref) {
  return SearchContent(ref.watch(searchRepositoryProvider));
});

class SearchPage {
  final List<SearchResult> results;
  final String? nextCursor;
  final bool hasMore;

  const SearchPage({
    required this.results,
    this.nextCursor,
    this.hasMore = false,
  });
}

final searchProvider = FutureProvider.autoDispose.family<SearchPage, String>((
  ref,
  query,
) async {
  if (query.isEmpty) {
    return const SearchPage(results: []);
  }
  final results = await ref.watch(searchContentProvider)(query);
  return SearchPage(
    results: results,
    nextCursor: null,
    hasMore: results.length >= 20,
  );
});
