import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/public_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_current_user_profile.dart';
import '../../domain/usecases/get_member_directory.dart';
import '../../domain/usecases/update_profile.dart';
import '../../data/repositories/profile_repository_impl.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final getCurrentUserProfileProvider = Provider<GetCurrentUserProfile>((ref) {
  return GetCurrentUserProfile(ref.watch(profileRepositoryProvider));
});

final updateProfileProvider = Provider<UpdateProfile>((ref) {
  return UpdateProfile(ref.watch(profileRepositoryProvider));
});

final getMemberDirectoryProvider = Provider<GetMemberDirectory>((ref) {
  return GetMemberDirectory(ref.watch(profileRepositoryProvider));
});

final currentUserProfileProvider = FutureProvider<AppUser?>((ref) {
  return ref.watch(getCurrentUserProfileProvider)();
});

final memberDirectoryProvider = FutureProvider.autoDispose
    .family<List<PublicProfile>, String?>((ref, query) {
      return ref.watch(getMemberDirectoryProvider)(query: query);
    });
