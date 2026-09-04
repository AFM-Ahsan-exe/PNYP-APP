import '../../domain/repositories/renewal_repository.dart';

class RejectRenewal {
  final RenewalRepository repository;

  RejectRenewal(this.repository);

  Future<void> call(String userId, {String? reason}) {
    return repository.rejectRenewal(userId, reason: reason);
  }
}
