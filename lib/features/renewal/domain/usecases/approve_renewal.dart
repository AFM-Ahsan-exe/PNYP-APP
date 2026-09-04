import '../../domain/repositories/renewal_repository.dart';

class ApproveRenewal {
  final RenewalRepository repository;

  ApproveRenewal(this.repository);

  Future<void> call(String userId, {String? membershipType}) {
    return repository.approveRenewal(userId, membershipType: membershipType);
  }
}
