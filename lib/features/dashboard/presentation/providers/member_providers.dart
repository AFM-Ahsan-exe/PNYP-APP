import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../../features/profile/domain/repositories/profile_repository.dart';
import '../../../../features/profile/data/repositories/profile_repository_impl.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final memberUserProvider = FutureProvider<AppUser?>((ref) async {
  return ref.watch(profileRepositoryProvider).getCurrentUserProfile();
});
