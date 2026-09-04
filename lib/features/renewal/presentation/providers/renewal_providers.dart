import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/renewal_request.dart';
import '../../domain/repositories/renewal_repository.dart';
import '../../domain/usecases/approve_renewal.dart';
import '../../domain/usecases/get_pending_renewals.dart';
import '../../domain/usecases/reject_renewal.dart';
import '../../domain/usecases/submit_renewal.dart';
import '../../data/repositories/renewal_repository_impl.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final renewalRepositoryProvider = Provider<RenewalRepository>((ref) {
  return RenewalRepositoryImpl(ref.watch(firebaseAuthProvider));
});

final submitRenewalProvider = Provider<SubmitRenewal>((ref) {
  return SubmitRenewal(ref.watch(renewalRepositoryProvider));
});

final getPendingRenewalsProvider = Provider<GetPendingRenewals>((ref) {
  return GetPendingRenewals(ref.watch(renewalRepositoryProvider));
});

final approveRenewalProvider = Provider<ApproveRenewal>((ref) {
  return ApproveRenewal(ref.watch(renewalRepositoryProvider));
});

final rejectRenewalProvider = Provider<RejectRenewal>((ref) {
  return RejectRenewal(ref.watch(renewalRepositoryProvider));
});

final pendingRenewalsProvider =
    FutureProvider.autoDispose<List<RenewalRequest>>((ref) {
      return ref.watch(getPendingRenewalsProvider)();
    });