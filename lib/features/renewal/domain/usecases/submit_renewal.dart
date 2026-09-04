import '../../domain/repositories/renewal_repository.dart';

class SubmitRenewal {
  final RenewalRepository repository;

  SubmitRenewal(this.repository);

  Future<void> call({
    required String userId,
    required String membershipType,
    required String paymentProofUrl,
  }) {
    return repository.submitRenewal(
      userId: userId,
      membershipType: membershipType,
      paymentProofUrl: paymentProofUrl,
    );
  }
}
