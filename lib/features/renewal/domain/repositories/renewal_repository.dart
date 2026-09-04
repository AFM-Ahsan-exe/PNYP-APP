import '../entities/renewal_request.dart';

abstract class RenewalRepository {
  Future<void> submitRenewal({
    required String userId,
    required String membershipType,
    required String paymentProofUrl,
  });

  Future<List<RenewalRequest>> getPendingRenewals();

  Future<void> approveRenewal(String userId, {String? membershipType});

  Future<void> rejectRenewal(String userId, {String? reason});
}
